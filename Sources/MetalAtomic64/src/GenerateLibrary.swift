//
//  GenerateLibrary.swift
//  
//
//  Created by Philip Turner on 12/15/22.
//

import Metal

#if METAL_ATOMIC64_C_INTERFACE
@_cdecl("metal_atomic64_generate_library")
public func metal_atomic64_generate_library(
  _ float64_library: UnsafeRawPointer?,
  _ atomic64_library: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
  _ lock_buffer: UnsafeMutablePointer<UnsafeMutableRawPointer?>
) {
  // Accept float64_library reference at +0.
  let _float64_library = Unmanaged<MTLDynamicLibrary>
    .fromOpaque(float64_library!).takeUnretainedValue()
  
  // Call into Swift version of the function (not visible from C). We make a
  // separate function for C because otherwise, it might incorrectly reference-
  // count the return values.
  let (_atomic64_library, _lock_buffer) =
    metal_atomic64_generate_library(_float64_library)
  
  // Return outputs at +1.
  atomic64_library.pointee = Unmanaged<MTLDynamicLibrary>
    .passRetained(_atomic64_library).toOpaque()
  lock_buffer.pointee = Unmanaged<MTLBuffer>
    .passRetained(_lock_buffer).toOpaque()
}
#endif

// NOTE: Ensure this documentation comment stays synchronized with the C header.

/// Compile a 64-bit atomics library that embeds the lock buffer's GPU virtual
/// address into the binary. This library eliminates the need to specify a lock
/// buffer when encoding commands.
///
/// To hard-code the lock buffer's GPU virtual address into the executable, we
/// must compile some code at runtime. This mini-dylib provides a C-accessible
/// function for generating the library. It returns an opaque pointer for the
/// `MTLDynamicLibrary` object and lock buffer object (both retain count +1).
/// Each invokation generates a brand new library and lock buffer. You are
/// responsible for decrementing their reference counts upon deallocation.
///
/// During the linking stage of compilation, MetalAtomic64 needs a copy of
/// libMetalFloat64. The Atomic64 library depends on the Float64 library,
/// although this dependency is not circular. The Float64 library doesn't
/// internally depend on the Atomic64 library. Its header just exposes symbols
/// for atomic functions. To make your shaders (which import the header) link
/// correctly, they must see libMetalAtomic64 at load time. Either (a) serialize
/// libMetalAtomic64 into the same directory as libMetalFloat64 or (b) add it to
/// the `preloadedLibraries` property of your pipeline descriptor.
///
/// The lock buffer is allocated on the `MTLDevice` that generated the
/// `float64_library` object. If this device is a discrete GPU, the buffer will
/// be in the private storage mode. Otherwise, it will be in the shared storage
/// mode. The buffer comes out zero-initialized, but you are responsible for
/// resetting it upon corruption. The lock buffer could become corrupted if the
/// GPU aborts a command buffer while one thread has acquired a lock, but not
/// yet released it.
///
/// If you're using this function from C or C++, you may have to copy the dylib
/// manually. In that case, it's compiled slightly different from the SwiftPM
/// version. The build script copies the shader code into the Swift file as a
/// string literal. This means you don't have to worry about whether shader
/// files are in the same directory as "libMetalAtomic64.dylib". The C/C++
/// compile path also packages a C header for the dynamic library.
///
/// - Parameters:
///   - float64_library: The MetalFloat64 library to link against.
///   - atomic64_library: The MetalAtomic64 library your client code will call
///     into.
///   - lock_buffer: The lock buffer whose base address is encoded into
///     `atomic64_library`.
public func metal_atomic64_generate_library(
  _ float64_library: MTLDynamicLibrary
) -> (
  atomic64_library: MTLDynamicLibrary,
  lock_buffer: MTLBuffer
) {
  // Fetch the float64 library's metal device.
  let device = float64_library.device
  
  // TODO: Determine the actual necessary length.
  let lockBufferLength = 128
  let bufferStorageMode = device.hasUnifiedMemory
    ? MTLResourceOptions.storageModeShared : .storageModePrivate
  let lockBuffer = device.makeBuffer(
    length: lockBufferLength, options: bufferStorageMode)!
  let lockBufferAddress = NSNumber(value: lockBuffer.gpuAddress)
  
  // Temporarily storing something (e.g "50") in the buffer's first 8 bytes,
  // to prove it was accessed successfully. A final implementation should erase
  // this code.
  let lockBufferContents = lockBuffer.contents()
    .assumingMemoryBound(to: UInt32.self)
  lockBufferContents[0] = 50
  
  let options = MTLCompileOptions()
  options.libraries = [float64_library]
  options.optimizationLevel = .size
  options.preprocessorMacros = [
    "METAL_ATOMIC64_LOCK_BUFFER_ADDRESS": lockBufferAddress
  ]
  options.libraryType = .dynamic
  options.installName = "@loader_path/libMetalAtomic64.metallib"
  let atomic64Library_raw = try! device.makeLibrary(
    source: shader_source, options: options)
  let atomic64Library = try! device.makeDynamicLibrary(
    library: atomic64Library_raw)
  
  return (atomic64Library, lockBuffer)
}

private let shader_source = """
//
//  Atomic.metal
//  
//
//  Created by Philip Turner on 12/16/22.
//

#include <metal_stdlib>
using namespace metal;

// When compiling sources at runtime, your only option is to expose all symbols
// by default. Therefore, we explicitly set the EXPORT macro to nothing.
#define EXPORT
#define NOEXPORT static

// Apply this to functions that shouldn't be inlined internally.
// Place at the function definition.
#define NOINLINE __attribute__((__noinline__))

// Apply this to force-inline functions internally.
// The Metal Standard Library uses it, so it should work reliably.
#define ALWAYS_INLINE __attribute__((__always_inline__))

// MARK: - Embedded Reference to Lock Buffer

#if defined(METAL_ATOMIC64_PLACEHOLDER)
static constant size_t lock_buffer_address = 0;
#else
static constant size_t lock_buffer_address = METAL_ATOMIC64_LOCK_BUFFER_ADDRESS;
#endif

struct LockBufferAddressWrapper {
  device uint* address;
};

NOEXPORT ALWAYS_INLINE device uint* __get_lock_buffer() {
  auto const_ref = reinterpret_cast<constant LockBufferAddressWrapper&>
    (lock_buffer_address);
  return const_ref.address;
};

// MARK: - Implementation of Exposed Functions

namespace MetalFloat64 {
extern uint increment(uint x);
}

namespace MetalAtomic64
{
/// We utilize the type ID at runtime to dynamically dispatch to different
/// functions. This approach minimizes the time necessary to compile
/// MetalAtomic64 from scratch at runtime, while reducing binary size. Also,
/// atomic operations will be memory bound, so the ALU time for switching over
/// enum cases should be hidden.
enum TypeID: ushort {
  i64 = 0, // signed long
  u64, // unsigned long
  f64, // IEEE double precision
  f59, // 59-bit reduced precision
  f43 // 43-bit reduced precision
};

EXPORT void __atomic_store_explicit(threadgroup ulong * object, ulong desired) {
  uint x = 1;
  x = MetalFloat64::increment(x);
  object[0] += x;
  threadgroup_barrier(mem_flags::mem_threadgroup);
}

EXPORT void __atomic_store_explicit(device ulong * object, ulong desired) {
  uint x = 1;
  x = MetalFloat64::increment(x);
  object[0] += x + __get_lock_buffer()[0];
}
} // namespace MetalAtomic64

""" // end copying here

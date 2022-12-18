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
  // Fetch the float64 library's Metal device.
  let device = float64_library.device
  
  let lockBufferLength = 65536 * MemoryLayout<UInt32>.stride
  let bufferStorageMode = device.hasUnifiedMemory
    ? MTLResourceOptions.storageModeShared : .storageModePrivate
  let lockBuffer = device.makeBuffer(
    length: lockBufferLength, options: bufferStorageMode)!
  let lockBufferAddress = NSNumber(value: lockBuffer.gpuAddress)
  
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
#define INTERNAL_INLINE NOEXPORT ALWAYS_INLINE

// MARK: - Embedded Reference to Lock Buffer

// Reference to existing implementation:
// https://github.com/kokkos/kokkos/blob/master/tpls/desul/include/desul/atomics/Lock_Array.hpp
//
// namespace desul {
// namespace Impl {
// struct host_locks__ {
//   static constexpr uint32_t HOST_SPACE_ATOMIC_MASK = 0xFFFF;
//   static constexpr uint32_t HOST_SPACE_ATOMIC_XOR_MASK = 0x5A39;
//   template <typename is_always_void = void>
//   static int32_t* get_host_locks_() {
//     static int32_t HOST_SPACE_ATOMIC_LOCKS_DEVICE[HOST_SPACE_ATOMIC_MASK + 1] = {0};
//     return HOST_SPACE_ATOMIC_LOCKS_DEVICE;
//   }
//   static inline int32_t* get_host_lock_(void* ptr) {
//     return &get_host_locks_()[((uint64_t(ptr) >> 2) & HOST_SPACE_ATOMIC_MASK) ^
//                               HOST_SPACE_ATOMIC_XOR_MASK];
//   }
// };

#if defined(METAL_ATOMIC64_PLACEHOLDER)
static constant size_t lock_buffer_address = 0;
#else
static constant size_t lock_buffer_address = METAL_ATOMIC64_LOCK_BUFFER_ADDRESS;
#endif

struct LockBufferAddressWrapper {
  device atomic_uint* address;
};

struct DeviceAddressWrapper {
  device atomic_uint* address;
};

// TODO: Remove this.
INTERNAL_INLINE device atomic_uint* __get_lock_buffer() {
  auto const_ref = reinterpret_cast<constant LockBufferAddressWrapper&>
    (lock_buffer_address);
  return const_ref.address;
};

INTERNAL_INLINE device atomic_uint* get_lock(device ulong* object) {
  DeviceAddressWrapper wrapper{ (device atomic_uint*)object };
  uint lower_bits = reinterpret_cast<thread uint2&>(wrapper)[0] >>= 3;
  ushort hash = as_type<ushort2>(lower_bits)[0] & 0x5A39;
  
  auto lock_ref = reinterpret_cast<constant LockBufferAddressWrapper&>
     (lock_buffer_address);
  return lock_ref.address + hash;
}

INTERNAL_INLINE void acquire_lock(device atomic_uint* lock) {
  while (true) {
    uint expected = 0;
    uint desired = 1;
    auto success = metal::atomic_compare_exchange_weak_explicit(
      lock, &expected, desired, memory_order_relaxed, memory_order_relaxed);
    if (success) {
      break;
    }
  }
}

INTERNAL_INLINE void release_lock(device atomic_uint* lock) {
  while (true) {
    uint expected = 1;
    uint desired = 0;
    auto success = metal::atomic_compare_exchange_weak_explicit(
      lock, &expected, desired, memory_order_relaxed, memory_order_relaxed);
    if (success) {
      break;
    }
    // The cmpxchg should never return false.
    // TODO: Test whether it ever does, then switch to a faster atomic_store
    // without a loop.
  }
}

// The address should be aligned, so simply mask the address before reading.
// That incurs (hopefully) one cycle overhead + register swaps, instead of
// four cycles overhead + register swaps.
INTERNAL_INLINE device atomic_uint* get_upper_address(device atomic_uint* lower) {
  DeviceAddressWrapper wrapper{ lower };
  auto bits = reinterpret_cast<thread uint2&>(wrapper);
  bits[0] &= 4;
  return reinterpret_cast<thread DeviceAddressWrapper&>(bits).address;
}

// Only call this while holding a lock.
INTERNAL_INLINE ulong memory_load(device atomic_uint* lower, device atomic_uint* upper) {
  uint out_lo = metal::atomic_load_explicit(lower, memory_order_relaxed);
  uint out_hi = metal::atomic_load_explicit(upper, memory_order_relaxed);
  return as_type<ulong>(uint2(out_lo, out_hi));
}

// Only call this while holding a lock.
INTERNAL_INLINE void memory_store(device atomic_uint *lower, device atomic_uint* upper, ulong desired) {
  uint in_lo = as_type<uint2>(desired)[0];
  uint in_hi = as_type<uint2>(desired)[1];
  metal::atomic_store_explicit(lower, in_lo, memory_order_relaxed);
  metal::atomic_store_explicit(upper, in_hi, memory_order_relaxed);
  
  // Validate that the written value reads what you expect.
  while (true) {
    if (desired == memory_load(lower, upper)) {
      break;
    }
    // TODO: Test how often the thread reads a value it didn't write.
  }
}

// MARK: - Implementation of Exposed Functions

namespace MetalFloat64 {
extern uint increment(uint x);
}

// Several operations are fused into common functions, reducing compile time and
// binary size by ~70%. More explanation is under `TypeID`.
// - group 1: add_i/u64, add_f64, add_f59, add_f43
// - group 2: sub_i/u64, sub_f64, sub_f59, sub_f43
// - group 3: max_i64, max_u64, max_f64, max_f59, max_f43
// - group 4: min_i64, min_u64, min_f64, min_f59, min_f43
// - group 5: and_i/u64, or_i/u64, xor_i/u64
// - group 6: cmpxchg_i/u64, cmpxchg_f64, cmpxchg_f59, cmpxchg_f43
// - group 7: store, load, xchg
namespace MetalAtomic64
{
// We utilize the type ID at runtime to dynamically dispatch to different
// functions. This approach minimizes the time necessary to compile
// MetalAtomic64 from scratch at runtime, while reducing binary size. Also,
// atomic operations will be memory bound, so the ALU time for switching over
// enum cases should be hidden.
enum TypeID: ushort {
  i64 = 0, // signed long
  u64 = 1, // unsigned long
  f64 = 2, // IEEE double precision
  f59 = 3, // 59-bit reduced precision
  f43 = 4 // 43-bit reduced precision
};

// Entering an invalid operation ID causes undefined behavior at runtime.
enum OperationID: ushort {
  store = 0,
  load = 1,
  xchg = 2,
  logical_and = 3,
  logical_or = 4,
  logical_xor = 5
};

// TODO: You can't just implement atomics through a threadgroup barrier. In
// between the barrier, two threads could still write to the same address.
// Solution: an __extremely__ slow workaround that takes the threadgroup memory
// pointer (presumably 32 bits), hashes both the upper and lower 16 bits, then
// uses the device lock buffer to synchronize.
//
// Alternatively, find some neat hack with bank conflicts that's inherently
// atomic. Perhaps stagger operations based on thread ID. We can also access
// the `SReg32` on Apple GPUs, which stores the thread's index in the
// threadgroup: https://github.com/dougallj/applegpu/blob/main/applegpu.py. Or,
// include the threadgroup's ID in the hash, minimizing conflicts over a common
// lock between threadgroups.
//
// It the threadgroup memory pointer size is truly indecipherable, and/or varies
// between Apple and AMD, try the following. Allocate 64 bits of register or
// stack memory. Write the threadgroup pointer to its base. Hash all 64 bits.
// As an optimization, also function-call into pre-compiled AIR code that
// fetches the threadgroup ID from an SReg32.
EXPORT void __atomic_store_explicit(threadgroup ulong* object, ulong desired) {
  // Ensuring binary dependency to MetalFloat64. TODO: Remove
  {
    uint x = 1;
    x = MetalFloat64::increment(x);
  }
  threadgroup_barrier(mem_flags::mem_threadgroup);
  object[0] = desired;
  threadgroup_barrier(mem_flags::mem_threadgroup);
}

EXPORT void __atomic_store_explicit(device ulong* object, ulong desired) {
  // Ensuring binary dependency to MetalFloat64. TODO: Remove
  {
    uint x = 1;
    x = MetalFloat64::increment(x);
  }
  object[0] = desired;
  __get_lock_buffer()[0];
}

EXPORT ulong __atomic_fetch_add_explicit(device ulong* object, ulong operand, TypeID type) {
//  object[0] += operand;
  
  auto lock = get_lock(object);
  acquire_lock(lock);
  
  auto lower = reinterpret_cast<device atomic_uint*>(object);
  auto upper = get_upper_address(lower);
  ulong previous = memory_load(lower, upper);
  ulong next = previous + operand;
  memory_store(lower, upper, next);
  
  release_lock(lock);
  return next;
}
} // namespace MetalAtomic64

""" // end copying here

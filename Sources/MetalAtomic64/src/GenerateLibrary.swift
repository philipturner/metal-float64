//
//  GenerateLibrary.swift
//  
//
//  Created by Philip Turner on 12/15/22.
//

import Metal

// TODO: Also create a dummy metallib for linking during the build process.
// TODO: Create a metallibsym from the dummy metallib.
// TODO: Change library from NSObject to MTLDynamicLibrary.
// TODO: Change lock_buffer from NSObject to MTLBuffer.

#if METAL_ATOMIC64_SWIFT_INTERFACE
/// To hard-code the lock buffer's GPU virtual address into the executable, we
/// must compile some code at runtime. This mini-dylib provides a C-accessible
/// function for generating the library. It returns an opaque pointer for the
/// `MTLDynamicLibrary` object and lock buffer object (both retain count +1).
/// Each invokation generates a brand new library and lock buffer. You are
/// responsible for decrementing their reference counts upon deallocation.
///
/// To make it link correctly, either (a) serialize it into the same directory
/// as libMetalFloat64 or (b) add it to the `preloadedLibraries` property of
/// your pipeline descriptor.
///
/// You must enter the device to allocate the lock buffer on. If this device is
/// a discrete GPU, the buffer will be in the private storage mode. Otherwise,
/// it will be in the shared storage mode. The buffer comes out
/// zero-initialized, but you are responsible for resetting it upon corruption.
/// The lock buffer could become corrupted if the GPU aborts a command buffer
/// while one thread has acquired a lock, but not yet released it.
///
/// If you're using this function from C or C++, you may have to copy the dylib
/// manually. In that case, it's compiled slightly different from the SwiftPM
/// version. The build script copies the shader code into the Swift file as a
/// string literal. This means you don't have to worry about whether shader
/// files are in the same directory as "libMetalAtomic64.dylib". The C/C++
/// compile path also packages a C header for the dynamic library.
///
/// - Parameters:
///   - device: Metal device to allocate the buffer on.
///   - library: The dynamic library to link into `libMetalFloat64.metallib`.
///   - lock_buffer: The lock buffer whose base address is encoded into `library`.
public func metal_atomic64_generate_library(
  _ device: MTLDevice,
  _ library: inout NSObject?,
  _ lock_buffer: inout NSObject?
) {
  (library, lock_buffer) = _metal_atomic64_generate_library(device)
}

#elseif METAL_ATOMIC64_C_INTERFACE
@_cdecl("metal_atomic64_generate_library")
public func metal_atomic64_generate_library(
  _ device: OpaquePointer?,
  _ library: UnsafeMutablePointer<OpaquePointer?>,
  _ lock_buffer: UnsafeMutablePointer<OpaquePointer?>
) {
  // Accept device reference at +0.
  let device: MTLDevice = Unmanaged
    .fromOpaque(.init(device!)).takeUnretainedValue()
  let (_library, _lock_buffer) = _metal_atomic64_generate_library(device)
  
  // Return outputs at +1.
  library.pointee = .init(Unmanaged.passRetained(_library).toOpaque())
  lock_buffer.pointee = .init(Unmanaged.passRetained(_lock_buffer).toOpaque())
}

#else
#error("Did not select a language for the function interface.")
#endif

private func _metal_atomic64_generate_library(_ device: MTLDevice) -> (NSObject, NSObject) {
  return (NSObject(), NSObject())
}

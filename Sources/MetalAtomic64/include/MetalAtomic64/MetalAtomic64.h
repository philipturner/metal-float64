//
//  MetalAtomic64.h
//  
//
//  Created by Philip Turner on 12/15/22.
//

#ifndef MetalAtomic64_h
#define MetalAtomic64_h

// Header for the MetalAtomic64 helper library. This should only be imported by
// CPU code, while "MetalFloat64.h" should be imported by GPU code.

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
void metal_atomic64_generate_library(
  const void *device, void **library, void **lock_buffer);

#endif /* MetalAtomic64_h */

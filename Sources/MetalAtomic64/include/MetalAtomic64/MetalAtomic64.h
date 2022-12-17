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
void metal_atomic64_generate_library(
  const void *float64_library, void **atomic64_library, void **lock_buffer);

#endif /* MetalAtomic64_h */

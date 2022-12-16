//
//  Atomic.metal
//  
//
//  Created by Philip Turner on 12/16/22.
//

#include <metal_stdlib>
using namespace metal;

// Apply this to exported symbols.
// Place at the function declaration.
#define EXPORT __attribute__((__visibility__("default")))

// Apply this to functions that shouldn't be inlined internally.
// Place at the function definition.
#define NOINLINE __attribute__((__noinline__))

// Apply this to force-inline functions internally.
// The Metal Standard Library uses it, so it should work reliably.
#define ALWAYS_INLINE __attribute__((__always_inline__))

// TODO: The actual MetalAtomic64 library needs to circularly depend on
// libMetalFloat64. This lets it perform floating-point operations under the
// hood with only two function calls. The dummy library does not need to do
// this, as it may break the build system. We need to declare certain double
// precision symbols as `extern` for the actual MetalFloat64 library.
//
// https://stackoverflow.com/a/66181478
//
// When making the real libMetalAtomic64, we may also need a dummy for
// libMetalFloat64. Nevermind ... libMetalFloat64 doesn't actually depend on
// libMetalAtomic64; its header just makes it appear to. We can use the
// libMetalFloat64 present on the device for this.

// TODO: Some of these functions require a type ID parameter. We'll utilize the
// type ID at runtime to dynamically dispatch to different functions. The
// approach also minimizes the time necessary to compile MetalAtomic64 from
// scratch at runtime. Finally, atomic operations will be memory bound, so the
// ALU time for switching over enum cases should be hidden.

EXPORT void __metal_atomic64_store_explicit(threadgroup ulong * object, ulong desired) {
  
}

EXPORT void __metal_atomic64_store_explicit(device ulong * object, ulong desired) {
  
}

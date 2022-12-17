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

namespace MetalAtomic64
{
/// We utilize the type ID at runtime to dynamically dispatch to different
/// functions. This approach minimizes the time necessary to compile
/// MetalAtomic64 from scratch at runtime, while reducing binary size. Also,
/// atomic operations will be memory bound, so the ALU time for switching over
/// enum cases should be hidden.
enum TypeID: ushort {
  i64 = 0,
  u64,
  f64,
  f59,
  f43
};

EXPORT void __atomic_store_explicit(threadgroup ulong * object, ulong desired) {
  
}

EXPORT void __atomic_store_explicit(device ulong * object, ulong desired) {
  
}
} // namespace MetalAtomic64

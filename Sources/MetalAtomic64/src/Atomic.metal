//
//  Atomic.metal
//  
//
//  Created by Philip Turner on 12/16/22.
//

#include <metal_stdlib>
using namespace metal;

// When compiling sources at runtime, your only option is to expose all symbols
// by default. We explicitly set the EXPORT macro to nothing.
#define EXPORT

// Apply this to functions that shouldn't be inlined internally.
// Place at the function definition.
#define NOINLINE __attribute__((__noinline__))

// Apply this to force-inline functions internally.
// The Metal Standard Library uses it, so it should work reliably.
#define ALWAYS_INLINE __attribute__((__always_inline__))

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
}

EXPORT void __atomic_store_explicit(device ulong * object, ulong desired) {
  uint x = 1;
  x = MetalFloat64::increment(x);
  object[0] += x;
}
} // namespace MetalAtomic64

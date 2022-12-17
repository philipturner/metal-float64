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

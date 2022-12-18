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
// https://github.com/kokkos/kokkos/blob/master/tpls/desul/include/desul/atomics/Lock_Array_HIP.hpp
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

INTERNAL_INLINE ulong atomic_load(device atomic_uint* lower, device atomic_uint* upper) {
  uint out_lo = metal::atomic_load_explicit(lower, memory_order_relaxed);
  uint out_hi = metal::atomic_load_explicit(upper, memory_order_relaxed);
  return as_type<ulong>(uint2(out_lo, out_hi));
}

// TODO: Test how often the thread reads a value it didn't write.
// atomic_store

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

EXPORT void __atomic_fetch_add_explicit(device ulong* object, ulong operand, TypeID type) {
  // TODO: Actually synchronize based on the lock
  object[0] += operand;
}
} // namespace MetalAtomic64

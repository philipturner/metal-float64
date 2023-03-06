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
//
// https://github.com/kokkos/kokkos/blob/master/tpls/desul/include/desul/atomics/Generic.hpp
//
////  This is a way to avoid dead lock in a warp or wave front
// T return_val;
// int done = 0;
// #ifdef __HIPCC__
// unsigned long long int active = DESUL_IMPL_BALLOT_MASK(1);
// unsigned long long int done_active = 0;
// while (active != done_active) {
//   if (!done) {
//     if (Impl::lock_address_hip((void*)dest, scope)) {
//       atomic_thread_fence(MemoryOrderAcquire(), scope);
//       return_val = op.apply(*dest, val);
//       *dest = return_val;
//       atomic_thread_fence(MemoryOrderRelease(), scope);
//       Impl::unlock_address_hip((void*)dest, scope);
//       done = 1;
//     }
//   }
//   done_active = DESUL_IMPL_BALLOT_MASK(done);
// }

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

// This assumes the object is aligned to 8 bytes (the address's lower 3 bits
// are all zeroes). Otherwise, behavior is undefined.
INTERNAL_INLINE device atomic_uint* get_lock(device ulong* object) {
  DeviceAddressWrapper wrapper{ (device atomic_uint*)object };
  uint lower_bits = reinterpret_cast<thread uint2&>(wrapper)[0];
  uint hash = extract_bits(lower_bits, 1, 18) ^ (0x5A39 << 2);
  
  // TODO: Explicitly, OR only the lower 32 bits (this currently sign extends).
  auto this_address = lock_buffer_address | hash;
  auto lock_ref = reinterpret_cast<thread LockBufferAddressWrapper&>
     (this_address);
  return lock_ref.address;
}

INTERNAL_INLINE bool try_acquire_lock(device atomic_uint* lock) {
  uint expected = 0;
  uint desired = 1;
  return metal::atomic_compare_exchange_weak_explicit(
    lock, &expected, desired, memory_order_relaxed, memory_order_relaxed);
}

INTERNAL_INLINE void release_lock(device atomic_uint* lock) {
  atomic_store_explicit(lock, 0, memory_order_relaxed);
}

// The address should be aligned, so simply mask the address before reading.
// That incurs (hopefully) one cycle overhead + register swap, instead of four
// cycles overhead + register swap. Not sure whether the increased register
// pressure is a bad thing.
INTERNAL_INLINE device atomic_uint* get_upper_address(device atomic_uint* lower) {
  DeviceAddressWrapper wrapper{ lower };
  auto lower_bits = reinterpret_cast<thread uint2&>(wrapper);
  uint2 upper_bits{ lower_bits[0] | 4, lower_bits[1] };
  return reinterpret_cast<thread DeviceAddressWrapper&>(upper_bits).address;
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
    } else {
      // This branch never happens, but it's necessary to prevent some kind of
      // compiler or runtime optimization.
    }
  }
}

// MARK: - Implementation of Exposed Functions

namespace metal_float64
{
extern uint increment(uint x);
} // namespace metal_float64

// We utilize the type ID at runtime to dynamically dispatch to different
// functions. This approach minimizes the time necessary to compile
// MetalAtomic64 from scratch at runtime, while reducing binary size. Also,
// atomic operations will be memory bound, so the ALU time for switching over
// enum cases should be hidden.
//
// Several operations are fused into common functions, reducing compile time and
// binary size by ~70%.
// - group 1: add_i/u64, add_f64, add_f59, add_f43
// - group 2: sub_i/u64, sub_f64, sub_f59, sub_f43
// - group 3: max_i64, max_u64, max_f64, max_f59, max_f43
// - group 4: min_i64, min_u64, min_f64, min_f59, min_f43
// - group 5: and_i/u64, or_i/u64, xor_i/u64
// - group 6: cmpxchg_i/u64, cmpxchg_f64, cmpxchg_f59, cmpxchg_f43
// - group 7: store, load, xchg
enum __metal_atomic64_type_id: ushort {
  i64 = 0, // signed long
  u64 = 1, // unsigned long
  f64 = 2, // IEEE double precision
  f59 = 3, // 59-bit reduced precision
  f43 = 4, // 43-bit reduced precision
  f32x2 = 5, // double-single approach
  f32 = 6, // software-emulated single precision for validation
};

// Entering an invalid operation ID causes undefined behavior at runtime.
enum __metal_atomic64_operation_id: ushort {
  store = 0, // atomic_store_explicit
  load = 1, // atomic_load_explicit
  xchg = 2, // atomic_exchange_explicit
  logical_and = 3, // atomic_fetch_and_explicit
  logical_or = 4, // atomic_fetch_or_explicit
  logical_xor = 5, // atomic_fetch_xor_explicit
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
// If the threadgroup memory pointer size is truly indecipherable, and/or varies
// between Apple and AMD, try the following. Allocate 64 bits of register or
// stack memory. Write the threadgroup pointer to its base. Hash all 64 bits.
// As an optimization, also function-call into pre-compiled AIR code that
// fetches the threadgroup ID from an SReg32. Incorporate that into the hash
// too.
EXPORT void __metal_atomic64_store_explicit(threadgroup ulong* object, ulong desired) {
  // Ensuring binary dependency to MetalFloat64. TODO: Remove
  {
    uint x = 1;
    x = metal_float64::increment(x);
  }
  threadgroup_barrier(mem_flags::mem_threadgroup);
  object[0] = desired;
  threadgroup_barrier(mem_flags::mem_threadgroup);
}

EXPORT void __metal_atomic64_store_explicit(device ulong* object, ulong desired) {
  // Ensuring binary dependency to MetalFloat64. TODO: Remove
  {
    uint x = 1;
    x = metal_float64::increment(x);
  }
  // acquire lock
  object[0] = desired;
  // release lock
}

// TODO: Transform this into a templated function.
EXPORT ulong __metal_atomic64_fetch_add_explicit(device ulong* object, ulong operand, __metal_atomic64_type_id type) {
  device atomic_uint* lock = get_lock(object);
  auto lower_address = reinterpret_cast<device atomic_uint*>(object);
  auto upper_address = get_upper_address(lower_address);
  ulong output;
  
  // Avoids a deadlock when threads in the same simdgroup access the same memory
  // location, during the same function call.
  bool done = false;
  simd_vote active = simd_active_threads_mask();
  simd_vote done_active(0);
  using vote_t = simd_vote::vote_t;
  
  while (vote_t(active) != vote_t(done_active)) {
    if (!done) {
      if (try_acquire_lock(lock)) {
        ulong previous = memory_load(lower_address, upper_address);
        output = previous + operand;
        memory_store(lower_address, upper_address, output);
        release_lock(lock);
        done = true;
      }
    }
    done_active = simd_ballot(done);
  }
  return output;
}

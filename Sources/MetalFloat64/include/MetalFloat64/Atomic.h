// MARK: - Atomic.h

// TODO: Wrap atomic<double> in a custom generic type, similar to how we evaded
// the name collision for custom vec<>.
// TODO: Use compiler macro to redirect ulong atomics to MetalFloat64.
// TODO: The API-side shim delegates to an actual function call which has two
// underscores.

// Actual functions exposed by the header.

namespace MetalFloat64
{
EXPORT uint increment(uint x);
EXPORT void __atomic_store_explicit(threadgroup long * object, long desired);
EXPORT void __atomic_store_explicit(device long * object, long desired);
EXPORT void __atomic_store_explicit(threadgroup ulong * object, ulong desired);
EXPORT void __atomic_store_explicit(device ulong * object, ulong desired);
}

// Ensure that public API matches the MSLib.

namespace MetalFloat64
{
using namespace metal;

template <typename T, typename _E = void>
struct _atomic
{
  _atomic() threadgroup = default;
  _atomic() device = delete;
  _atomic(const threadgroup _atomic &) threadgroup = delete;
  _atomic(const device _atomic &) threadgroup = delete;
  _atomic(const threadgroup _atomic &) device = delete;
  _atomic(const device _atomic &) device = delete;
  threadgroup _atomic &operator=(const threadgroup _atomic &) threadgroup = delete;
  threadgroup _atomic &operator=(const device _atomic &) threadgroup = delete;
  device _atomic &operator=(const threadgroup _atomic &) device = delete;
  device _atomic &operator=(const device _atomic &) device = delete;
};

template <typename T>
using atomic = _atomic<T>;

template <typename T>
struct _atomic<T, typename enable_if<_disjunction<
  is_same<T, long>,
  is_same<T, ulong>
>::value>::type>
{
  _atomic() threadgroup = default;
  _atomic() device = delete;
  _atomic(const threadgroup _atomic &) threadgroup = delete;
  _atomic(const device _atomic &) threadgroup = delete;
  _atomic(const threadgroup _atomic &) device = delete;
  _atomic(const device _atomic &) device = delete;
  threadgroup _atomic &operator=(const threadgroup _atomic &) threadgroup = delete;
  threadgroup _atomic &operator=(const device _atomic &) threadgroup = delete;
  device _atomic &operator=(const threadgroup _atomic &) device = delete;
  device _atomic &operator=(const device _atomic &) device = delete;
  
  T __s;
};
typedef _atomic<long> atomic_long;
typedef _atomic<ulong> atomic_ulong;

#pragma METAL internals : enable
template <typename T, typename _E = void>
struct _valid_store_type : false_type
{
};

template <typename T>
struct _valid_store_type<T, typename enable_if<_disjunction<
  is_same<T, device long *>,
  is_same<T, threadgroup long *>,
  is_same<T, device ulong *>,
  is_same<T, threadgroup ulong *>
>::value>::type> : true_type
{
};
#pragma METAL internals : disable

template <typename T, typename U, typename _E = typename enable_if<_valid_store_type<threadgroup T *>::value && is_convertible<T, U>::value>::type>
METAL_FUNC void atomic_store_explicit(volatile threadgroup _atomic<T> * object, U desired, memory_order order) METAL_CONST_ARG(order) METAL_VALID_STORE_ORDER(order)
{
  __atomic_store_explicit(&object->__s, decltype(object->__s)(desired));
}
template <typename T, typename U, typename _E = typename enable_if<_valid_store_type<device T *>::value && is_convertible<T, U>::value>::type>
METAL_FUNC void atomic_store_explicit(volatile device _atomic<T> *object, U desired, memory_order order) METAL_CONST_ARG(order) METAL_VALID_STORE_ORDER(order)
{
  // TODO: Why doesn't this fail at compile-time?
  __atomic_store_explicit(&object->__s, decltype(object->__s)(desired), int(order), __METAL_MEMORY_SCOPE_DEVICE__);
}

namespace
{

}

} // namespace MetalFloat64

// Bypass the name collision between `metal::` and `MetalFloat64::` atomics.

// move namespace enclosure here

#define _atomic MetalFloat64::__common_atomic
#define atomic MetalFloat64::__common_atomic

// Hopefully, functions don't name-collide.
// TODO: Ensure the functions didn't alias by checking runtime behavior.

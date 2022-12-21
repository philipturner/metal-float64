// MARK: - Atomic.h

// TODO: Wrap atomic<double> in a custom generic type, similar to how we evaded
// the name collision for custom vec<>.
// TODO: Use compiler macro to redirect ulong atomics to MetalFloat64, if
// needed. May need an "actual_func" for each of these.
// TODO: Ensure the functions didn't alias by checking runtime behavior.

// Actual functions exposed by the header.

enum __metal_atomic64_type_id: ushort {
  i64 = 0,
  u64 = 1,
  f64 = 2,
  f59 = 3,
  f43 = 4
};

extern void __metal_atomic64_store_explicit(threadgroup ulong* object, ulong desired);
extern void __metal_atomic64_store_explicit(device ulong* object, ulong desired);
extern ulong __metal_atomic64_fetch_add_explicit(device ulong* object, ulong operand, __metal_atomic64_type_id type);

namespace metal_float64
{
EXPORT uint increment(uint x);
} // namespace metal_float64

// Ensure that public API matches the MSLib.

namespace metal_float64
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
  __metal_atomic64_store_explicit(
    (threadgroup ulong*)&object->__s,
    as_type<ulong>(decltype(object->__s)(desired)));
}
template <typename T, typename U, typename _E = typename enable_if<_valid_store_type<device T *>::value && is_convertible<T, U>::value>::type>
METAL_FUNC void atomic_store_explicit(volatile device _atomic<T> *object, U desired, memory_order order) METAL_CONST_ARG(order) METAL_VALID_STORE_ORDER(order)
{
  __metal_atomic64_store_explicit(
    (device ulong*)&object->__s,
    as_type<ulong>(decltype(object->__s)(desired)));
}

// Bypass the name collision between `metal::atomic` and
// `metal_float64::atomic`.

namespace
{
template <typename T>
struct __atomic_base {};

#define MAKE_METAL_BASE(T) \
template <> \
struct __atomic_base<T> { \
  using actual_atomic = metal::atomic<T>; \
}; \

MAKE_METAL_BASE(bool);
MAKE_METAL_BASE(int);
MAKE_METAL_BASE(uint);
MAKE_METAL_BASE(float);

#define MAKE_METAL_FLOAT64_BASE(T) \
template <> \
struct __atomic_base<T> { \
  using actual_atomic = metal_float64::atomic<T>; \
}; \

#undef MAKE_METAL_FLOAT64_BASE
#undef MAKE_METAL_BASE
} // namespace

// TODO: __metal_float64_common_atomic

} // namespace metal_float64




#define _atomic metal_float64::__metal_float64_common_atomic
#define atomic metal_float64::__metal_float64_common_atomic

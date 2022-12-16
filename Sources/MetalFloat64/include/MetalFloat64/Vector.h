// MARK: - Vector.h

namespace MetalFloat64
{

// Vectors cannot be implemented through the compiler, but luckily we can work
// around this. Matrices could be implemented similarly.
// https://stackoverflow.com/a/51822107

// TODO: support device, constant, threadgroup, ray_data address spaces
// TODO: support packed_double2, packed_double3, packaged_double4
// TODO: support vector component accessors from vec<1>, vec<4>
// TODO: support swizzles such as .xxx and .xyxx on all vectors
// TODO: find a good way to encapsulate a vector's internal array, since it
// can't be made private.

// TODO: See if there's a way to statically check a vector's length, and force
// negative vectors to not compile.
template <typename T, unsigned int N, typename _E = void>
class vec {
  T v[N];
};

namespace
{
template <typename T, unsigned int I>
class scalar_swizzle
{
  T v[1];
public:
  thread T &operator=(const thread T x)
  {
    v[I] = x;
    return v[I];
  }
  operator T() const
  {
    return v[I];
  }
  T operator++(int)
  {
    return v[I]++;
  }
  T operator++()
  {
    return ++v[I];
  }
  T operator--(int)
  {
    return v[I]--;
  }
  T operator--()
  {
    return --v[I];
  }
};

// We use a vec_type in a template instead of forward declarations to prevent
// errors in some compilers.
template<typename T, unsigned int A, unsigned int B, typename vec_type = vec<T, 2>>
class vec2_swizzle
{
  T d[2];
public:
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(d[A] = vec.x, d[B] = vec.y);
  }
  operator vec_type()
  {
    return vec_type(d[A], d[B]);
  }
};

template <typename T, unsigned int A, unsigned int B, unsigned int C, typename vec_type = vec<T, 3>>
class vec3_swizzle
{
  T d[3];
public:
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(d[A] = vec.x, d[B] = vec.y, d[C] = vec.z);
  }
  operator vec_type()
  {
    
    return vec_type(d[A], d[B], d[C]);
  }
};
} // namespace

template <typename T>
class vec<T, 2>
{
public:
  union
  {
    T d[2];
    
  public:
#define VEC2_SWIZZLES \
scalar_swizzle<T, 0> x, r; \
scalar_swizzle<T, 1> y, g; \
vec2_swizzle<T, 0, 0> xx, rr; \
vec2_swizzle<T, 0, 1> xy, rg; \
vec2_swizzle<T, 1, 0> yx, gr; \
vec2_swizzle<T, 1, 1> yy, gg; \

    VEC2_SWIZZLES;
  };
public:
  vec() {}
  vec(T all)
  {
    x = y = all;
  }
  vec(T a, T b)
  {
    x = a;
    y = b;
  }
};

template <typename T>
class vec<T, 3>
{
public:
  union
  {
  public:
    T d[3];
    
  public:
#define VEC3_SWIZZLES \
VEC2_SWIZZLES; \
scalar_swizzle<T, 2> z, b; \
vec2_swizzle<T, 0, 2> xz, rb; \
vec2_swizzle<T, 2, 0> zx, br; \
vec2_swizzle<T, 1, 2> yz, gb; \
vec2_swizzle<T, 2, 1> zy, bg; \
vec3_swizzle<T, 0, 1, 2> xyz, rgb; \
vec3_swizzle<T, 0, 2, 1> xzy, rbg; \
vec3_swizzle<T, 1, 0, 2> yxz, grb; \
vec3_swizzle<T, 1, 2, 0> yzx, gbr; \
vec3_swizzle<T, 2, 0, 1> zxy, brg; \
vec3_swizzle<T, 2, 1, 0> zyx, bgr; \

    VEC3_SWIZZLES;
  };
public:
  vec() {}
  vec(T all)
  {
    x = y = z = all;
  }
  vec(T a, T b, T c)
  {
    x = a;
    y = b;
    z = c;
  }
};

#undef VEC3_SWIZZLES
#undef VEC2_SWIZZLES
}

// Bypass the name collision between `metal::vec` and `MetalFloat64::vec`.

namespace MetalFloat64 {

namespace
{
template <typename T, uint I>
struct base {};

#define MAKE_METAL_BASE(T) \
template <unsigned int I> \
struct base<T, I> { \
  using actual_vec = metal::vec<T, I>; \
}; \

MAKE_METAL_BASE(float);

#undef MAKE_METAL_BASE

template <unsigned int I>
struct base<float64_t, I> {
  using actual_vec = vec<float64_t, I>;
};
} // namespace

template <typename T, unsigned int I>
using __common_vec = typename base<T, I>::actual_vec;

} // namespace MetalFloat64

#define vec MetalFloat64::__common_vec

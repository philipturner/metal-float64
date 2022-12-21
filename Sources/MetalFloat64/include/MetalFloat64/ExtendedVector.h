// MARK: - ExtendedVector.h

// Vector types based on the default precision.
#define double2 vec<double, 2>
#define double3 vec<double, 3>
#define double4 vec<double, 4>

namespace MetalFloat64
{
// Vectors cannot be implemented through the compiler, but luckily we can work
// around this. Matrices could be implemented similarly (Matrix.h).
// https://stackoverflow.com/a/51822107

// TODO: support device, constant, threadgroup, ray_data address spaces
// TODO: support packed_double2, packed_double3, packed_double4
// TODO: support vector component accessors from vec<1>, vec<4>
// TODO: support swizzles such as .xxx and .xyxx on all vectors
// TODO: support subscripts

// TODO: See if there's a way to statically check a vector's length, and force
// negative vectors to not compile.
template <typename T, uint N, typename _E = void>
class vec {
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[N];
};

// MARK: - Swizzle Accessors

namespace
{
template <typename T, uint I>
class scalar_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[1];
public:
  thread T &operator=(const thread T x)
  {
    _data[I] = x;
    return _data[I];
  }
  operator T() const
  {
    return _data[I];
  }
  T operator++(int)
  {
    return _data[I]++;
  }
  T operator++()
  {
    return ++_data[I];
  }
  T operator--(int)
  {
    return _data[I]--;
  }
  T operator--()
  {
    return --_data[I];
  }
};

// We use a vec_type in a template instead of forward declarations to prevent
// errors in some compilers.
template<typename T, uint A, uint B, typename vec_type = vec<T, 2>>
class vec2_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[2];
public:
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  operator vec_type()
  {
    return vec_type(_data[A], _data[B]);
  }
};

template <typename T, uint A, uint B, uint C, typename vec_type = vec<T, 3>>
class vec3_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[3];
public:
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y, _data[C] = vec.z);
  }
  operator vec_type()
  {
    return vec_type(_data[A], _data[B], _data[C]);
  }
};

template <typename T, uint A, uint B, uint C, uint D, typename vec_type = vec<T, 4>>
class vec4_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[4];
public:
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y, _data[C] = vec.z, _data[D] = vec.w);
  }
  operator vec_type()
  {
    return vec_type(_data[A], _data[B], _data[C], _data[D]);
  }
};

// TODO: Incorporate 4-wide swizzles into everything.

#define VEC1_SWIZZLE_GROUP(i, x, r) \
scalar_swizzle<T, i> x, r; \
vec2_swizzle<T, i, i> x##x, r##r; \
vec3_swizzle<T, i, i, i> x##x##x, r##r##r; \
vec4_swizzle<T, i, i, i, i> x##x##x##x, r##r##r##r; \

#define VEC2_SWIZZLE_GROUP(i, j, x, y, r, g) \
vec2_swizzle<T, i, j> x##y, r##g; \
vec3_swizzle<T, i, i, j> x##x##y, r##r##g; \
vec3_swizzle<T, i, j, i> x##y##x, r##g##r; \
vec3_swizzle<T, i, j, j> x##y##y, r##g##g; \
vec4_swizzle<T, i, i, i, j> x##x##x##y, r##r##r##g; \
vec4_swizzle<T, i, i, j, i> x##x##y##x, r##r##g##r; \
vec4_swizzle<T, i, i, j, j> x##x##y##y, r##r##g##g; \
vec4_swizzle<T, i, j, i, i> x##y##x##x, r##g##r##r; \
vec4_swizzle<T, i, j, i, j> x##y##x##y, r##g##r##g; \
vec4_swizzle<T, i, j, j, i> x##y##y##x, r##g##g##r; \
vec4_swizzle<T, i, j, j, j> x##y##y##y, r##g##g##g; \

// TODO: Split this into three groups.

#define VEC3_SWIZZLE_GROUP \
vec3_swizzle<T, 0, 1, 2> xyz, rgb; \
vec3_swizzle<T, 0, 2, 1> xzy, rbg; \
vec3_swizzle<T, 1, 0, 2> yxz, grb; \
vec3_swizzle<T, 1, 2, 0> yzx, gbr; \
vec3_swizzle<T, 2, 0, 1> zxy, brg; \
vec3_swizzle<T, 2, 1, 0> zyx, bgr; \

#define VEC4_SWIZZLE_GROUP

} // namespace

// MARK: - Class Template Specializations

template <typename T>
class vec<T, 1>
{
public:
  union
  {
    // Must be public as an internal implementation detail, but the user should
    // never access this property.
    T _data[1];
    
  public:
#define VEC1_ALL_SWIZZLES \
    VEC1_SWIZZLE_GROUP(0, x, r); \

    VEC1_ALL_SWIZZLES;
  };
public:
  vec() {}
  vec(T a)
  {
    x = a;
  }
};

template <typename T>
class vec<T, 2>
{
public:
  union
  {
    // Must be public as an internal implementation detail, but the user should
    // never access this property.
    T _data[2];
    
  public:
#define VEC2_ALL_SWIZZLES \
    VEC1_ALL_SWIZZLES; \
    VEC1_SWIZZLE_GROUP(1, y, g); \
    VEC2_SWIZZLE_GROUP(0, 1, x, y, r, g); \
    VEC2_SWIZZLE_GROUP(1, 0, y, x, g, r); \

    VEC2_ALL_SWIZZLES;
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
    // Must be public as an internal implementation detail, but the user should
    // never access this property.
    T _data[3];
    
  public:
    VEC2_ALL_SWIZZLES;
    VEC1_SWIZZLE_GROUP(2, z, b); \
    VEC2_SWIZZLE_GROUP(0, 2, x, z, r, b);
    VEC2_SWIZZLE_GROUP(2, 0, z, x, b, r);
    VEC2_SWIZZLE_GROUP(1, 2, y, z, g, b);
    VEC2_SWIZZLE_GROUP(2, 1, z, y, b, g);
    VEC3_SWIZZLE_GROUP;
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

#undef VEC4_ALL_SWIZZLES
#undef VEC3_ALL_SWIZZLES
#undef VEC2_ALL_SWIZZLES
#undef VEC1_ALL_SWIZZLES

#undef VEC4_SWIZZLE_GROUP
#undef VEC3_SWIZZLE_GROUP
#undef VEC2_SWIZZLE_GROUP
#undef VEC1_SWIZZLE_GROUP

// Bypass the name collision between `metal::vec` and `MetalFloat64::vec`.

namespace
{
template <typename T, uint I>
struct __base_vec {};

#define MAKE_METAL_BASE(T) \
template <uint I> \
struct __base_vec<T, I> { \
  using actual_vec = metal::vec<T, I>; \
}; \

MAKE_METAL_BASE(bool);
MAKE_METAL_BASE(char);
MAKE_METAL_BASE(uchar);
MAKE_METAL_BASE(short);
MAKE_METAL_BASE(ushort);
MAKE_METAL_BASE(int);
MAKE_METAL_BASE(uint);
MAKE_METAL_BASE(long);
MAKE_METAL_BASE(ulong);
MAKE_METAL_BASE(half);
MAKE_METAL_BASE(float);

#define MAKE_METAL_FLOAT64_BASE(T) \
template <uint I> \
struct __base_vec<T, I> { \
  using actual_vec = vec<T, I>; \
}; \

MAKE_METAL_FLOAT64_BASE(float64_t);
MAKE_METAL_FLOAT64_BASE(float59_t);
MAKE_METAL_FLOAT64_BASE(float43_t);

#undef MAKE_METAL_FLOAT64_BASE
#undef MAKE_METAL_BASE
} // namespace

template <typename T, uint I>
using __metal_float64_common_vec = typename __base_vec<T, I>::actual_vec;

} // namespace MetalFloat64

// Enter the workaround into the `metal` namespace and global context.

using MetalFloat64::__metal_float64_common_vec;

namespace metal {
using MetalFloat64::__metal_float64_common_vec;
}

#define vec __metal_float64_common_vec

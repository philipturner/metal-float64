// MARK: - ExtendedVector.h

// Vector types based on the default precision.
#define double2 vec<double, 2>
#define double3 vec<double, 3>
#define double4 vec<double, 4>

namespace metal_float64
{
// Vectors cannot be implemented through the compiler, but luckily we can work
// around this.
// https://stackoverflow.com/a/51822107

// TODO: support thread, device, constant, threadgroup, thread_imageblock, ray_data, object_data address spaces
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warray-bounds"

#define VEC_SIMPLE_CTORS(COPY_CTOR) \
vec() thread = default; \
vec() device = default; \
vec() constant = default; \
vec() threadgroup = default; \
vec() threadgroup_imageblock = default; \
vec() ray_data = default; \
vec() object_data = default; \
\
COPY_CTOR(thread); \
COPY_CTOR(device); \
COPY_CTOR(constant); \
COPY_CTOR(threadgroup); \
COPY_CTOR(threadgroup_imageblock); \
COPY_CTOR(ray_data); \
COPY_CTOR(object_data); \

#define VEC_SWIZZLE_ALL_CTORS(CTORS) \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, thread); \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, device); \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, constant); \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, threadgroup); \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, threadgroup_imageblock); \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, ray_data); \
VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, object_data); \

#define VEC_SWIZZLE_ALL_CTORS_INTERNAL(CTORS, ADDRSPACE2) \
CTORS(thread, ADDRSPACE2); \
CTORS(device, ADDRSPACE2); \
CTORS(constant, ADDRSPACE2); \
CTORS(threadgroup, ADDRSPACE2); \
CTORS(threadgroup_imageblock, ADDRSPACE2); \
CTORS(ray_data, ADDRSPACE2); \
CTORS(object_data, ADDRSPACE2); \

#define VEC_SWIZZLE_CONVERT_OPERATORS(OPERATOR) \
OPERATOR(thread); \
OPERATOR(device); \
OPERATOR(constant); \
OPERATOR(threadgroup); \
OPERATOR(threadgroup_imageblock); \
OPERATOR(ray_data); \
OPERATOR(object_data); \

namespace
{
template <typename T, uint A, typename vec_type = vec<T, 1>>
class vec1_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[1];
public:
#define VEC1_SWIZZLE_CTORS(ADDRSPACE1, ADDRSPACE2) \
template <uint X> \
vec_type operator=(const ADDRSPACE1 vec1_swizzle<T, X>& vec) ADDRSPACE2 { \
  return *this = vec_type(vec); \
} \
vec_type operator=(const ADDRSPACE1 vec_type& vec) ADDRSPACE2 { \
  return vec_type(_data[A] = vec.x); \
} \

  VEC_SWIZZLE_ALL_CTORS(VEC1_SWIZZLE_CTORS);
  
#define VEC1_SWIZZLE_CONVERT_OPERATOR(ADDRSPACE) \
  operator vec_type() const ADDRSPACE \
  { \
    return vec_type(_data[A]); \
  } \
  operator T() const ADDRSPACE \
  { \
    return _data[A]; \
  } \

  VEC_SWIZZLE_CONVERT_OPERATORS(VEC1_SWIZZLE_CONVERT_OPERATOR);
  
  T operator++(int)
  {
    return _data[A]++;
  }
  T operator++()
  {
    return ++_data[A];
  }
  T operator--(int)
  {
    return _data[A]--;
  }
  T operator--()
  {
    return --_data[A];
  }
};

template <typename T, uint A, uint B, typename vec_type = vec<T, 2>>
class vec2_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[2];
public:
#define VEC2_SWIZZLE_CTORS(ADDRSPACE1, ADDRSPACE2) \
template <uint X, uint Y> \
vec_type operator=(const ADDRSPACE1 vec2_swizzle<T, X, Y>& vec) ADDRSPACE2 { \
  return *this = vec_type(vec); \
} \
vec_type operator=(const ADDRSPACE1 vec_type& vec) ADDRSPACE2 { \
  return vec_type(_data[A] = vec.x, _data[B] = vec.y); \
} \

  VEC_SWIZZLE_ALL_CTORS(VEC2_SWIZZLE_CTORS);

#define VEC2_SWIZZLE_CONVERT_OPERATOR(ADDRSPACE) \
  operator vec_type() const ADDRSPACE \
  { \
    return vec_type(_data[A], _data[B]); \
  } \

  VEC_SWIZZLE_CONVERT_OPERATORS(VEC2_SWIZZLE_CONVERT_OPERATOR);
};

template <typename T, uint A, uint B, uint C, typename vec_type = vec<T, 3>>
class vec3_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[3];
public:
#define VEC3_SWIZZLE_CTORS(ADDRSPACE1, ADDRSPACE2) \
template <uint X, uint Y, uint Z> \
vec_type operator=(const ADDRSPACE1 vec3_swizzle<T, X, Y, Z>& vec) ADDRSPACE2 { \
  return *this = vec_type(vec); \
} \
vec_type operator=(const ADDRSPACE1 vec_type& vec) ADDRSPACE2 { \
  return vec_type(_data[A] = vec.x, _data[B] = vec.y, _data[C] = vec.z); \
} \

  VEC_SWIZZLE_ALL_CTORS(VEC3_SWIZZLE_CTORS);
  
#define VEC3_SWIZZLE_CONVERT_OPERATOR(ADDRSPACE) \
  operator vec_type() const ADDRSPACE \
  { \
    return vec_type(_data[A], _data[B], _data[C]); \
  } \

  VEC_SWIZZLE_CONVERT_OPERATORS(VEC3_SWIZZLE_CONVERT_OPERATOR);
};

template <typename T, uint A, uint B, uint C, uint D, typename vec_type = vec<T, 4>>
class vec4_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[4];
public:
#define VEC4_SWIZZLE_CTORS(ADDRSPACE1, ADDRSPACE2) \
template <uint X, uint Y, uint Z, uint W> \
vec_type operator=(const ADDRSPACE1 vec4_swizzle<T, X, Y, Z, W>& vec) ADDRSPACE2 { \
  return *this = vec_type(vec); \
} \
vec_type operator=(const ADDRSPACE1 vec_type& vec) ADDRSPACE2 { \
  return vec_type(_data[A] = vec.x, _data[B] = vec.y, _data[C] = vec.z, _data[D] = vec.w); \
} \
  
  VEC_SWIZZLE_ALL_CTORS(VEC4_SWIZZLE_CTORS);
  
#define VEC4_SWIZZLE_CONVERT_OPERATOR(ADDRSPACE) \
  operator vec_type() const ADDRSPACE \
  { \
    return vec_type(_data[A], _data[B], _data[C], _data[D]); \
  } \

  VEC_SWIZZLE_CONVERT_OPERATORS(VEC4_SWIZZLE_CONVERT_OPERATOR);
};

#undef VEC4_SWIZZLE_CTORS
#undef VEC3_SWIZZLE_CTORS
#undef VEC2_SWIZZLE_CTORS
#undef VEC1_SWIZZLE_CTORS

#pragma clang diagnostic ignored "-Wunused-value"
#pragma clang diagnostic pop

// Validating number of permutations:
// vec2_swizzle: (1^2) / 1 = 1
// vec3_swizzle: (1^3) / 1 = 1
// vec4_swizzle: (1^4) / 1 = 1
#define VEC1_SWIZZLE_GROUP(i, x, r) \
vec1_swizzle<T, i> x, r; \
vec2_swizzle<T, i, i> x##x, r##r; \
vec3_swizzle<T, i, i, i> x##x##x, r##r##r; \
vec4_swizzle<T, i, i, i, i> x##x##x##x, r##r##r##r; \

// Validating number of permutations:
// vec2_swizzle: (2^2 - 2(1)) / 2 = 1
// vec3_swizzle: (2^3 - 2(1)) / 2 = 3
// vec4_swizzle: (2^4 - 2(1)) / 2 = 7
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

// Validating number of permutations:
// vec3_swizzle: (3^3 - 3x2(3) - 3(1)) / 3 = 2
// vec4_swizzle: (3^4 - 3x2(7) - 3(1)) / 3 = 12
#define VEC3_SWIZZLE_GROUP(i, j, k, x, y, z, r, g, b) \
vec3_swizzle<T, i, j, k> x##y##z, r##g##b; \
vec4_swizzle<T, i, i, j, k> x##x##y##z, r##r##g##b; \
vec4_swizzle<T, i, j, k, i> x##y##z##x, r##g##b##r; \
vec4_swizzle<T, i, j, i, k> x##y##x##z, r##g##r##b; \
vec4_swizzle<T, j, i, i, k> y##x##x##z, g##r##r##b; \
vec4_swizzle<T, j, i, k, i> y##x##z##x, g##r##b##r; \
vec4_swizzle<T, j, k, i, i> y##z##x##x, g##b##r##r; \
\
vec3_swizzle<T, i, k, j> x##z##y, r##b##g; \
vec4_swizzle<T, i, i, k, j> x##x##z##y, r##r##b##g; \
vec4_swizzle<T, i, k, j, i> x##z##y##x, r##b##g##r; \
vec4_swizzle<T, i, k, i, j> x##z##x##y, r##b##r##g; \
vec4_swizzle<T, k, i, i, j> z##x##x##y, b##r##r##g; \
vec4_swizzle<T, k, i, j, i> z##x##y##x, b##r##g##r; \
vec4_swizzle<T, k, j, i, i> z##y##x##x, b##g##r##r; \

// Validating number of permutations:
// vec4_swizzle: (4^4 - 4x3(12) - 4x3(7) - 4(1)) / 4 = 6
#define VEC4_SWIZZLE_GROUP(i, j, k, l, x, y, z, w, r, g, b, a) \
vec4_swizzle<T, i, j, k, l> x##y##z##w, r##g##b##a; \
vec4_swizzle<T, i, j, l, k> x##y##w##z, r##g##a##b; \
vec4_swizzle<T, i, k, j, l> x##z##y##w, r##b##g##a; \
vec4_swizzle<T, i, k, l, j> x##z##w##y, r##b##a##g; \
vec4_swizzle<T, i, l, j, k> x##w##y##z, r##a##g##b; \
vec4_swizzle<T, i, l, k, j> x##w##z##y, r##a##b##g; \

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
    T _data[1] __attribute__((aligned(8)));
    
  public:
#define VEC1_ALL_SWIZZLES \
VEC1_SWIZZLE_GROUP(0, x, r); \

    VEC1_ALL_SWIZZLES
  };
public:
#define VEC1_COPY_CTOR(ADDRSPACE) \
vec(const ADDRSPACE vec& a)  \
{ \
  x = a; \
} \

  VEC_SIMPLE_CTORS(VEC1_COPY_CTOR);
  
  vec(T a)
  {
    x = a;
  }
  
#define VEC1_CTORS(ADDRSPACE1, ADDRSPACE2) \
template <uint A> \
vec(const ADDRSPACE1 vec1_swizzle<T, A>& a) ADDRSPACE2 \
: vec(vec(a)) {} \

  VEC_SWIZZLE_ALL_CTORS(VEC1_CTORS);
};

template <typename T>
class vec<T, 2>
{
public:
  union
  {
    // Must be public as an internal implementation detail, but the user should
    // never access this property.
    T _data[2] __attribute__((aligned(16)));
    
  public:
#define VEC2_ALL_SWIZZLES \
VEC1_ALL_SWIZZLES \
VEC1_SWIZZLE_GROUP(1, y, g); \
VEC2_SWIZZLE_GROUP(0, 1, x, y, r, g); \
VEC2_SWIZZLE_GROUP(1, 0, y, x, g, r); \

    VEC2_ALL_SWIZZLES;
  };
public:
#define VEC2_COPY_CTOR(ADDRSPACE) \
vec(const ADDRSPACE vec& ab) \
{ \
  xy = ab; \
} \

  VEC_SIMPLE_CTORS(VEC2_COPY_CTOR);
  
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
    T _data[3] __attribute__((aligned(32)));
    
  public:
#define VEC3_ALL_SWIZZLES \
VEC2_ALL_SWIZZLES; \
VEC1_SWIZZLE_GROUP(2, z, b); \
VEC2_SWIZZLE_GROUP(0, 2, x, z, r, b); \
VEC2_SWIZZLE_GROUP(2, 0, z, x, b, r); \
VEC2_SWIZZLE_GROUP(1, 2, y, z, g, b); \
VEC2_SWIZZLE_GROUP(2, 1, z, y, b, g); \
VEC3_SWIZZLE_GROUP(0, 1, 2, x, y, z, r, g, b); \
VEC3_SWIZZLE_GROUP(1, 2, 0, y, z, x, g, b, r); \
VEC3_SWIZZLE_GROUP(2, 0, 1, z, x, y, b, r, g); \

    VEC3_ALL_SWIZZLES;
  };
public:
#define VEC3_COPY_CTOR(ADDRSPACE) \
vec(const ADDRSPACE vec& abc) \
{ \
  xyz = abc; \
} \

  VEC_SIMPLE_CTORS(VEC3_COPY_CTOR);
  
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
  
  vec(vec<T, 2> ab, T c)
  {
    xy = ab;
    z = c;
  }
  vec(T a, vec<T, 2> bc)
  {
    x = a;
    yz = bc;
  }
};

template <typename T>
class vec<T, 4>
{
public:
  union
  {
  public:
    // Must be public as an internal implementation detail, but the user should
    // never access this property.
    T _data[4] __attribute__((aligned(32)));
    
  public:
#define VEC4_ALL_SWIZZLES \
VEC3_ALL_SWIZZLES; \
VEC1_SWIZZLE_GROUP(3, w, a); \
VEC2_SWIZZLE_GROUP(0, 3, x, w, r, a); \
VEC2_SWIZZLE_GROUP(3, 0, w, x, a, r); \
VEC2_SWIZZLE_GROUP(1, 3, y, w, g, a); \
VEC2_SWIZZLE_GROUP(3, 1, w, y, a, g); \
VEC2_SWIZZLE_GROUP(2, 3, z, w, b, a); \
VEC2_SWIZZLE_GROUP(3, 2, w, z, a, b); \
\
VEC3_SWIZZLE_GROUP(0, 1, 3, x, y, w, r, g, a); \
VEC3_SWIZZLE_GROUP(0, 2, 3, x, z, w, r, b, a); \
VEC3_SWIZZLE_GROUP(1, 2, 3, y, z, w, g, b, a); \
VEC3_SWIZZLE_GROUP(1, 3, 0, y, w, x, g, a, r); \
VEC3_SWIZZLE_GROUP(2, 3, 0, z, w, x, b, a, r); \
VEC3_SWIZZLE_GROUP(2, 3, 1, z, w, y, b, a, g); \
VEC3_SWIZZLE_GROUP(3, 0, 1, w, x, y, a, r, g); \
VEC3_SWIZZLE_GROUP(3, 0, 2, w, x, z, a, r, b); \
VEC3_SWIZZLE_GROUP(3, 1, 2, w, y, z, a, g, b); \
\
VEC4_SWIZZLE_GROUP(0, 1, 2, 3, x, y, z, w, r, g, b, a); \
VEC4_SWIZZLE_GROUP(1, 2, 3, 0, y, z, w, x, g, b, a, r); \
VEC4_SWIZZLE_GROUP(2, 3, 0, 1, z, w, x, y, b, a, r, g); \
VEC4_SWIZZLE_GROUP(3, 0, 1, 2, w, x, y, z, a, r, g, b); \

    VEC4_ALL_SWIZZLES
  };
public:
#define VEC4_COPY_CTOR(ADDRSPACE) \
vec(const ADDRSPACE vec& abcd) \
{ \
  xyzw = abcd; \
} \

  VEC_SIMPLE_CTORS(VEC4_COPY_CTOR);
  
  vec(T all)
  {
    x = y = z = w = all;
  }
  vec(T a, T b, T c, T d)
  {
    x = a;
    y = b;
    z = c;
    w = d;
  }
  
  vec(vec<T, 3> abc, T d)
  {
    xyz = abc;
    w = d;
  }
  vec(T a, vec<T, 3> bcd)
  {
    x = a;
    yzw = bcd;
  }
  
  vec(vec<T, 2> ab, vec<T, 2> cd)
  {
    x = ab.x;
    y = ab.y;
    z = cd.x;
    w = cd.y;
  }
  vec(vec<T, 2> ab, T c, T d)
  {
    xy = ab;
    z = c;
    w = d;
  }
  vec(T a, vec<T, 2> bc, T d)
  {
    x = a;
    yz = bc;
    w = d;
  }
  vec(T a, T b, vec<T, 2> cd)
  {
    x = a;
    y = b;
    zw = cd;
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

#undef VEC_SWIZZLE_CONVERT_OPERATORS
#undef VEC_SWIZZLE_ALL_CTORS_INTERNAL
#undef VEC_SWIZZLE_ALL_CTORS
#undef VEC_SIMPLE_CTORS

// Bypass the name collision between `metal::vec` and `metal_float64::vec`.

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

} // namespace metal_float64

// Enter the workaround into the `metal` namespace and global context.

using metal_float64::__metal_float64_common_vec;

namespace metal {
using metal_float64::__metal_float64_common_vec;
}

#define vec __metal_float64_common_vec

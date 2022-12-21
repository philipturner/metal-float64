// MARK: - ExtendedVector.h

// Vector types based on the default precision.
#define double2 vec<double, 2>
#define double3 vec<double, 3>
#define double4 vec<double, 4>

namespace metal_float64
{
// Vectors cannot be implemented through the compiler, but luckily we can work
// around this. We haven't implemented matrices or packed vectors yet.
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

namespace
{
template <typename T, uint I>
class scalar_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[1];
public:
  thread T &operator=(const thread T& x) thread
  {
    _data[I] = x;
    return _data[I];
  }
  device T &operator=(const device T& x) device
  {
    _data[I] = x;
    return _data[I];
  }
  constant T &operator=(const constant T& x) constant
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
template <typename T, uint A, uint B, typename vec_type = vec<T, 2>>
class vec2_swizzle
{
  // Must be public as an internal implementation detail, but the user should
  // never access this property.
  T _data[2];
public:
  // TODO: Wrap all this address space boilerplate in macros.
  // TODO: Can I remove all these implicit constructors?
  
//  // thread
//  template <uint X, uint Y>
//  vec2_swizzle(const thread vec2_swizzle<T, X, Y>& vec) thread : vec2_swizzle(vec_type(vec)) {
//
//  }
//  template <uint X, uint Y>
//  vec2_swizzle(const device vec2_swizzle<T, X, Y>& vec) thread : vec2_swizzle(vec_type(vec)) {
//
//  }
//  template <uint X, uint Y>
//  vec2_swizzle(const constant vec2_swizzle<T, X, Y>& vec) thread : vec2_swizzle(vec_type(vec)) {
//
//  }
//
//  // device
//  template <uint X, uint Y>
//  vec2_swizzle(const thread vec2_swizzle<T, X, Y>& vec) device : vec2_swizzle(vec_type(vec)) {
//
//  }
//  template <uint X, uint Y>
//  vec2_swizzle(const device vec2_swizzle<T, X, Y>& vec) device : vec2_swizzle(vec_type(vec)) {
//
//  }
//  template <uint X, uint Y>
//  vec2_swizzle(const constant vec2_swizzle<T, X, Y>& vec) device : vec2_swizzle(vec_type(vec)) {
//
//  }
//
//  // constant
//  template <uint X, uint Y>
//  vec2_swizzle(const thread vec2_swizzle<T, X, Y>& vec) constant : vec2_swizzle(vec_type(vec)) {
//
//  }
//  template <uint X, uint Y>
//  vec2_swizzle(const device vec2_swizzle<T, X, Y>& vec) constant : vec2_swizzle(vec_type(vec)) {
//
//  }
//  template <uint X, uint Y>
//  vec2_swizzle(const constant vec2_swizzle<T, X, Y>& vec) constant : vec2_swizzle(vec_type(vec)) {
//
//  }
  
  // thread
  template <uint X, uint Y>
  vec_type operator=(const thread vec2_swizzle<T, X, Y>& vec) thread {
    return *this = vec_type(vec);
  }
  template <uint X, uint Y>
  vec_type operator=(const device vec2_swizzle<T, X, Y>& vec) thread {
    return *this = vec_type(vec);
  }
  template <uint X, uint Y>
  vec_type operator=(const constant vec2_swizzle<T, X, Y>& vec) thread {
    return *this = vec_type(vec);
  }
  
  // device
  template <uint X, uint Y>
  vec_type operator=(const thread vec2_swizzle<T, X, Y>& vec) device {
    return *this = vec_type(vec);
  }
  template <uint X, uint Y>
  vec_type operator=(const device vec2_swizzle<T, X, Y>& vec) device {
    return *this = vec_type(vec);
  }
  template <uint X, uint Y>
  vec_type operator=(const constant vec2_swizzle<T, X, Y>& vec) device {
    return *this = vec_type(vec);
  }
  
  // constant
  template <uint X, uint Y>
  vec_type operator=(const thread vec2_swizzle<T, X, Y>& vec) constant {
    return *this = vec_type(vec);
  }
  template <uint X, uint Y>
  vec_type operator=(const device vec2_swizzle<T, X, Y>& vec) constant {
    return *this = vec_type(vec);
  }
  template <uint X, uint Y>
  vec_type operator=(const constant vec2_swizzle<T, X, Y>& vec) constant {
    return *this = vec_type(vec);
  }
  
  // thread
  vec_type operator=(const thread vec_type& vec) thread
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  vec_type operator=(const device vec_type& vec) thread
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  vec_type operator=(const constant vec_type& vec) thread
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }

  // device
  vec_type operator=(const thread vec_type& vec) device
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  vec_type operator=(const device vec_type& vec) device
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  vec_type operator=(const constant vec_type& vec) device
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  
  // constant
  vec_type operator=(const thread vec_type& vec) constant
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  vec_type operator=(const device vec_type& vec) constant
  {
    return vec_type(_data[A] = vec.x, _data[B] = vec.y);
  }
  vec_type operator=(const constant vec_type& vec) constant
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

#pragma clang diagnostic ignored "-Wunused-value"
#pragma clang diagnostic pop

// Validating number of permutations:
// vec2_swizzle: (1^2) / 1 = 1
// vec3_swizzle: (1^3) / 1 = 1
// vec4_swizzle: (1^4) / 1 = 1
#define VEC1_SWIZZLE_GROUP(i, x, r) \
scalar_swizzle<T, i> x, r; \
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
  vec(const thread vec<T, 2>& ab) thread
  {
    xy = ab;
  }
  vec(const device vec<T, 2>& ab) device
  {
    xy = ab;
  }
  vec(const constant vec<T, 2>& ab) constant
  {
    xy = ab;
  }
  template <uint A, uint B>
  vec(const thread vec2_swizzle<T, A, B>& ab) thread : vec(vec(ab)) {}
  template <uint A, uint B>
  vec(const device vec2_swizzle<T, A, B>& ab) thread : vec(vec(ab)) {}
  template <uint A, uint B>
  vec(const constant vec2_swizzle<T, A, B>& ab) thread : vec(vec(ab)) {}
  
  template <uint A, uint B>
  vec(const thread vec2_swizzle<T, A, B>& ab) device : vec(vec(ab)) {}
  template <uint A, uint B>
  vec(const device vec2_swizzle<T, A, B>& ab) device : vec(vec(ab)) {}
  template <uint A, uint B>
  vec(const constant vec2_swizzle<T, A, B>& ab) device : vec(vec(ab)) {}
  
  template <uint A, uint B>
  vec(const thread vec2_swizzle<T, A, B>& ab) constant : vec(vec(ab)) {}
  template <uint A, uint B>
  vec(const device vec2_swizzle<T, A, B>& ab) constant : vec(vec(ab)) {}
  template <uint A, uint B>
  vec(const constant vec2_swizzle<T, A, B>& ab) constant : vec(vec(ab)) {}
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
  vec(const thread vec<T, 3>& abc) thread
  {
    xyz = abc;
  }
  vec(const device vec<T, 3>& abc) device
  {
    xyz = abc;
  }
  vec(const constant vec<T, 3>& abc) constant
  {
    xyz = abc;
  }
  template <uint A, uint B, uint C>
  vec(const thread vec3_swizzle<T, A, B, C>& abc) thread : vec(abc) {}
  template <uint A, uint B, uint C>
  vec(const device vec3_swizzle<T, A, B, C>& abc) device : vec(abc) {}
  template <uint A, uint B, uint C>
  vec(const constant vec3_swizzle<T, A, B, C>& abc) constant : vec(abc) {}
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
  vec() {}
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
  vec(const thread vec<T, 4>& abcd) thread
  {
    xyzw = abcd;
  }
  vec(const device vec<T, 4>& abcd) device
  {
    xyzw = abcd;
  }
  vec(const constant vec<T, 4>& abcd) constant
  {
    xyzw = abcd;
  }
  template <uint A, uint B, uint C, uint D>
  vec(const thread vec4_swizzle<T, A, B, C, D>& abcd) thread : vec(abcd) {}
  template <uint A, uint B, uint C, uint D>
  vec(const device vec4_swizzle<T, A, B, C, D>& abcd) device : vec(abcd) {}
  template <uint A, uint B, uint C, uint D>
  vec(const constant vec4_swizzle<T, A, B, C, D>& abcd) constant : vec(abcd) {}
};

#undef VEC4_ALL_SWIZZLES
#undef VEC3_ALL_SWIZZLES
#undef VEC2_ALL_SWIZZLES
#undef VEC1_ALL_SWIZZLES

#undef VEC4_SWIZZLE_GROUP
#undef VEC3_SWIZZLE_GROUP
#undef VEC2_SWIZZLE_GROUP
#undef VEC1_SWIZZLE_GROUP

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

// MARK: - Vector.h

namespace MetalFloat64
{

// Vectors cannot be implemented through the compiler, but luckily we can work
// around this.
// https://stackoverflow.com/a/51822107

template<unsigned int I>
struct scalar_swizzle
{
  float v[1];
  thread float &operator=(const thread float x)
  {
    v[I] = x;
    return v[I];
  }
  operator float() const
  {
    return v[I];
  }
  float operator++(int)
  {
    return v[I]++;
  }
  float operator++()
  {
    return ++v[I];
  }
  float operator--(int)
  {
    return v[I]--;
  }
  float operator--()
  {
    return --v[I];
  }
};

// We use a vec_type in a template instead of forward declartions to prevent
// errors in some compilers.
template<typename vec_type, unsigned int A, unsigned int B>
struct vec2_swizzle
{
  float d[2];
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(d[A] = vec.x, d[B] = vec.y);
  }
  operator vec_type()
  {
    return vec_type(d[A], d[B]);
  }
};

struct vec2
{
  union
  {
    float d[2];
    scalar_swizzle<0> x, r, s;
    scalar_swizzle<1> y, g, t;
    vec2_swizzle<vec2, 0, 0> xx;
    vec2_swizzle<vec2, 1, 1> yy;
  };
  vec2() {}
  vec2(float all)
  {
    x = y = all;
  }
  vec2(float a, float b)
  {
    x = a;
    y = b;
  }
};

template<typename vec_type, unsigned int A, unsigned int B, unsigned int C>
struct vec3_swizzle
{
  float d[3];
  vec_type operator=(const thread vec_type& vec)
  {
    return vec_type(d[A] = vec.x, d[B] = vec.y, d[C] = vec.z);
  }
  operator vec_type()
  {
    return vec_type(d[A], d[B], d[C]);
  }
};

struct vec3
{
  union
  {
    float d[3];
    scalar_swizzle<0> x, r;
    scalar_swizzle<1> y, g;
    scalar_swizzle<2> z, b;
    vec2_swizzle<vec2, 0, 1> xy;
    vec2_swizzle<vec2, 1, 2> yz;
    vec3_swizzle<vec3, 0, 1, 2> xyz;
    vec3_swizzle<vec3, 2, 1, 0> zyx;
  };
  vec3() {}
  vec3(float all)
  {
    x = y = z = all;
  }
  vec3(float a, float b, float c)
  {
    x = a;
    y = b;
    z = c;
  }
};

} // namespace MetalFloat64

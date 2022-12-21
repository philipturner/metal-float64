//
//  ExtendedVectorTests.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <metal_float64>
using namespace metal;
using namespace metal_float64;

// TODO: Run the test function that tests address spaces.

inline void test_double_redefinition() {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic ignored "-Wunused-value"
  double dvar1;
  double2 dvar2;
  double3 dvar3;
  double4 dvar4;
  vec<double, 1> dvar5;
  vec<double, 2> dvar6;
  vec<double, 3> dvar7;
  metal_float64::vec<double, 4> dvar8;
  vec<double, 5> dvar9;
  
  dvar2.xy = dvar3.yx;
  dvar3.bgr = dvar3.bgr;
  dvar4.xywz = dvar2.xxyx;
  
  float fvar1;
  float2 fvar2;
  float3 fvar3;
  float4 fvar4;
  vec<float, 1> fvar5;
  metal::vec<float, 2> fvar6;
  vec<float, 3> fvar7;
  vec<float, 4> fvar8;
  vec<float, 5> fvar9;
  
  fvar2.xy = fvar3.yx;
  fvar3.bgr = fvar3.bgr;
  fvar4.xywz = fvar2.xxyx;
#pragma clang diagnostic pop
}

// TODO: Test arithmetic functions on vectors.
// TODO: Test mixed swizzle and normal data types for complex vector constructors.
// TODO: Test scalar swizzles.
kernel void testExtendedVectorsCompile
 (
  device double3 *buffer1 [[buffer(0)]],
  constant double3 *buffer2 [[buffer(1)]]
  /*only one thread should ever be dispatched*/)
{
  double3 temp_value = double3(float64_t());
  temp_value.yz = buffer1[0].rg;
  temp_value.xz = buffer2[0].rg;
  buffer1[1].yz = temp_value.xy;
}

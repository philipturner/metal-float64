//
//  VectorTests.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <metal_float64>
using namespace metal;

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
//  dvar4.xyz = (dvar2.xxy).xxy; // Not possible
  
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
  fvar4.xyz = (fvar2.xxy).xxy;
  
  float3 fvector = fvar3;
  double3 dvector = dvar3;
  
  // Legal:
  fvector = float3(fvector.xyz);
  dvector = double3(dvector.xyz);
  fvector = fvector.xyz;
  dvector = dvector.xyz;
  
  // Legal:
  fvector = float3(fvector.xyz).xyz;
  dvector = double3(dvector.xyz).xyz;
  fvector = (fvector.xyz).xyz;
  
  // Illegal:
  // dvector = (dvector.xyz).xyz;
#pragma clang diagnostic pop
}

kernel void testExtendedVectorsCompile
 (
  device double3 *buffer1 [[buffer(0)]],
  constant double3 *buffer2 [[buffer(1)]],
  device double4 *buffer3 [[buffer(2)]]
  /*only one thread should ever be dispatched*/)
{
  // TODO: Validate that this all produces expected results.
  // TODO: After validating this, introduce subscripts (either bug-prone or have
  // limitations to note in README).
  double3 temp_value = double3(float64_t());
  temp_value.yz = buffer1[0].rg;
  temp_value.xz = buffer2[0].rg;
  temp_value.y = buffer2[0].b;
  buffer3[0].yz = temp_value.xy;
  
  double temp_scalar = temp_value.z;
  buffer3[0].x = temp_scalar;
  buffer3[1] = double4(buffer1[0].gr, ((device double2*)buffer1)[0]);
  
  threadgroup double4 tg_doubles[4];
  tg_doubles[0] = double4
   (
    ((device double*)(buffer1 + 1))[0],
    ((constant double*)(buffer2 + 1))[0],
    temp_value.y,
    ((device double4*)(buffer1 + 1))[1].a);
  
  tg_doubles[1] = double4
   (
    ((device double2*)(buffer1 + 2))[0],
    ((constant double2*)(buffer2 + 2))[0].yx);
  tg_doubles[2] = double4
   (
    ((device double2*)(buffer1 + 2))[0],
    ((constant double2*)(buffer2 + 2))[0]);
  tg_doubles[3] = double4
   (
    ((device double2*)(buffer1 + 2))[0].xy,
    ((constant double2*)(buffer2 + 2))[0].yx);
  buffer3[11].rbaa = tg_doubles[0].xyzw;
  buffer3[12].rbaa = double4(tg_doubles[1].xyzw);
  buffer3[13] = double3(tg_doubles[1].xyz).xyzz;
  
  device double2 *buffer1_v2 = (device double2*)buffer1;
  constant double2 *buffer2_v2 = (constant double2*)buffer2;
  constant double *buffer2_v1 = (constant double*)buffer2;
  buffer3[14] = double4(double3(buffer1_v2[0], buffer2_v1[0]), buffer2_v1[1]);
  buffer3[15] = double4(temp_value.yx, buffer2_v2[0]);
  buffer3[16] = double4(buffer2_v2[0], temp_value.yx);
  
//  tg_doubles[2] = double4((device double2*)buffer1)
  
//  buffer3[0] = tg_doubles[0].xxwy;
  
//  threadgroup double4 tg_doubles[1];
}

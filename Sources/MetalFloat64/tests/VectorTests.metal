//
//  VectorTests.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;
using namespace MetalFloat64;

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
  vec<double, 4> dvar8;
  vec<double, 5> dvar9;
  
  dvar2.xy;
  dvar3.bgr;
  
  float fvar1;
  float2 fvar2;
  float3 fvar3;
  float4 fvar4;
  vec<float, 1> fvar5;
  vec<float, 2> fvar6;
  vec<float, 3> fvar7;
  vec<float, 4> fvar8;
  vec<float, 5> fvar9;
  
  fvar2.xy;
  fvar3.bgr;
  fvar2.xyxx;
#pragma clang diagnostic pop
}

// Reference function
//kernel void testFunctionCallOverhead
// ( // This parenthesis trick bypasses Xcode's auto-indentation.
//  device TEST_TYPE *input [[buffer(0)]],
//  device int *output [[buffer(1)]],
//  device int *num_bytes [[buffer(2)]],
//  device int *increment_amount [[buffer(3)]],
//  uint tid [[thread_position_in_grid]])
//{
//  output[tid] = _testFunctionCallOverhead<TEST_TYPE, TEST_INCREMENT>
//   (
//    input, num_bytes, increment_amount);
//}

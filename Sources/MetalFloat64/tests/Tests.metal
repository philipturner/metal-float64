//
//  Tests.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;

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

//
//  Tests.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;

typedef double_t float_type;

kernel void testFullScreenColor(device float_type *input1 [[buffer(0)]],
                                device float4 *input2 [[buffer(1)]],
                                uint tid [[thread_position_in_grid]])
{
  if (tid == 0) {
    // Erases the color's last component and returns it.
    float4 color = input2[0];
    color = AAPLUserDylib::getFullScreenColor(color);
    input2[0] = color;
  }
}

//kernel void testCallStackOverFlow(device float_type *input1 [[buffer(0)]],
//                                  device float4 *input2 [[buffer(1)]],
//                                  uint tid [[thread_position_in_grid]])
//{
//  if (tid == 31) {
//    // Erases the color's last component and returns it.
//    float4 color = input2[0];
//    float4 color2 = color + 2;
//    float4 color4 = color + 4;
//    float4 color6 = color + 6;
//    float4 color8 = color + 8;
//    float4 color10 = color + 10;
//
//    // Try to create a stack overflow.
//    color = AAPLUserDylib::getFullScreenColor(color);
//    input2[0] = color;
//    input2[0] = input2[0] * color2;
//    input2[0] = input2[0] * color4;
//    input2[0] = input2[0] * color6;
//    input2[0] = input2[0] * color8;
//    input2[0] = input2[0] * color10;
////    input2[0] = color;
//  }
//}

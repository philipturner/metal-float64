//
//  Double.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;

typedef double_t my_double_t;

NEVER_INLINE float4 AAPLUserDylib::getFullScreenColor(float4 inColor)
{
  int x = 2;
#pragma clang loop unroll(full)
  for (int i = 0; i < 4; ++i) {
    x += 1;
  }
  
  return float4(inColor.r, inColor.g, inColor.b, 0);
}

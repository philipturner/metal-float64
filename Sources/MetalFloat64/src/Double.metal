//
//  Double.metal
//  
//
//  Created by Philip Turner on 11/22/22.
//

#include <metal_stdlib>
#include "Double.h"
using namespace metal;

typedef double_t my_double_t;

NEVER_INLINE float4 AAPLUserDylib::getFullScreenColor(float4 inColor)
{
    return float4(inColor.r, inColor.g, inColor.b, 0);
}

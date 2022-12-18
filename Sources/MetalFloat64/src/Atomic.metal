//
//  Atomic.metal
//  
//
//  Created by Philip Turner on 12/15/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;
using namespace MetalFloat64;

// TODO: Remove this entire file.

ALWAYS_INLINE uint MetalFloat64::increment(uint x) {
  return x + 1;
}

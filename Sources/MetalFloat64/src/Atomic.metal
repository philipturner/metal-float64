//
//  Atomic.metal
//  
//
//  Created by Philip Turner on 12/15/22.
//

#include <metal_stdlib>
#include <metal_float64>
using namespace metal;

// TODO: Remove this entire file.

ALWAYS_INLINE uint metal_float64::increment(uint x) {
  return x + 1;
}

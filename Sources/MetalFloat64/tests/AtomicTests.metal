//
//  AtomicTests.metal
//
//
//  Created by Philip Turner on 12/15/22.
//

#include <metal_stdlib>
#include <MetalFloat64/MetalFloat64.h>
using namespace metal;
using namespace MetalFloat64;

kernel void testAtomicsCompile(
  device void *input [[buffer(0)]],
  device void *output [[buffer(1)]],
  uint tid [[thread_position_in_grid]])
{
  auto int_input = (device int*)input;
  auto int_output = (device int*)output;
  int_output[tid] = increment(int_input[tid]);
  
  // TODO: Atomics for int, uint, long, ulong
  // TODO: Add argument for lock buffer
  auto ulong_output = (device ulong*)output;
  MetalAtomic64::__atomic_store_explicit(ulong_output + tid, 1);
}

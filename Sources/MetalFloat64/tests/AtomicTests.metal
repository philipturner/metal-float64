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
using namespace MetalAtomic64; // TODO: Remove

kernel void testAtomicsCompile(
  device void *input [[buffer(0)]],
  device void *output [[buffer(1)]],
  uint tid [[thread_position_in_grid]])
{
  auto int_input = (device int*)input;
  auto int_output = (device int*)output;
  int_output[tid] = increment(int_input[tid]);
  
  // TODO: Atomics for int, uint, long, ulong - test that they all compile.
  auto ulong_output = (device ulong*)output;
  MetalAtomic64::__atomic_store_explicit(ulong_output + tid, 1);
}

struct RandomData {
  uint index;
  ulong value;
};

struct DeviceAddressWrapper {
  device atomic_uint* address;
};

kernel void testAtomicAdd(
  constant uint &itemsPerThread [[buffer(0)]],
  device RandomData *randomData [[buffer(1)]],
  device ulong *outBuffer [[buffer(2)]],
  device ulong *errors [[buffer(3)]],
  uint tid [[thread_position_in_grid]])
{
  uint randomDataAddr = tid * itemsPerThread;
  for (uint i = 0; i < itemsPerThread; ++i) {
    auto this_data = randomData[randomDataAddr + i];
//    outBuffer[this_data.index] += this_data.value;
    [[maybe_unused]] ulong error = __atomic_fetch_add_explicit(
     outBuffer + this_data.index, this_data.value, u64);
    
    if (error > 0) {
      errors[tid] = randomDataAddr * 100000 + error;
    }
//    outBuffer[0] = sum;
  }
}

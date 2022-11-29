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

kernel void testCallStackOverFlow(device uint *flags [[buffer(0)]],
                                  device float4 *input2 [[buffer(1)]],
                                  uint tid [[thread_position_in_grid]])
{
  float4 color = input2[tid];
  color = AAPLUserDylib::attemptCallStackOverflow1(color, flags);
  input2[tid] = color;
}

// Functions to sum a vectorized intermediate.

int process_element(int x) {
  return x;
}

int process_element(int2 x) {
  return x[0] + x[1];
}

int process_element(int4 x) {
  return x[0] + x[1] + x[2] + x[3];
}

// Reads from an input buffer, increments, and returns the sum.
// - All threads operate on the exact same data.
// - Acquire 'num_bytes' from RAM to prevent compile-time optimizations.
template <typename T, T modify(T x)>
int _testFunctionCallOverhead
 (
  device T *input,
  device int *num_bytes,
  device int *ops_multiplier)
{
  int count = *num_bytes / sizeof(T);
  int _ops_multiplier = *ops_multiplier;
  int sum = 0;
  for (int i = 0; i < count; ++i)
  {
    T original_element = input[i];
    for (int j = 0; j < _ops_multiplier; ++j)
    {
      T element = original_element;
      element = modify(element);
      sum += process_element(element);
    }
  }
  return sum;
}

template <typename T>
T inlined_increment(T input)
{
  return input + 1;
}

#define TEST_TYPE int4
#define TEST_INCREMENT inlined_increment

kernel void testFunctionCallOverhead
 ( // This parenthesis trick bypasses Xcode's auto-indentation.
  device TEST_TYPE *input [[buffer(0)]],
  device int *output [[buffer(1)]],
  device int *num_bytes [[buffer(2)]],
  device int *ops_multiplier [[buffer(3)]],
  uint tid [[thread_position_in_grid]])
{
  output[tid] = _testFunctionCallOverhead<TEST_TYPE, TEST_INCREMENT>
   (
    input, num_bytes, ops_multiplier);
}

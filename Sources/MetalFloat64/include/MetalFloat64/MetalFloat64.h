//
//  MetalFloat64.h
//  
//
//  Created by Philip Turner on 11/22/22.
//

#ifndef MetalFloat64_h
#define MetalFloat64_h

// Single-file header for the MetalFloat64 library.

#include <metal_stdlib>
using namespace metal;

// Apply this to exported symbols.
// Place at the function declaration.
#define EXPORT __attribute__((__visibility__("default")))

// Apply this to functions that shouldn't be inlined internally.
// Place at the function definition.
#define NEVER_INLINE __attribute__((__noinline__))

class double_t {
  ulong data;
};

namespace AAPLUserDylib
{
  // Dummy function, just to test that dynamic linking works.
  EXPORT float4 getFullScreenColor(float4 inColor);
  EXPORT float4 attemptCallStackOverflow1(float4 input);
  EXPORT float4 attemptCallStackOverflow2(float4 input);
}

#endif /* MetalFloat64_h */

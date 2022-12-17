//
//  MetalAtomic64.h
//  
//
//  Created by Philip Turner on 12/15/22.
//

#ifndef MetalAtomic64_h
#define MetalAtomic64_h

// Header for the MetalAtomic64 helper library. This should only be imported by
// CPU code, while "MetalFloat64.h" should be imported by GPU code.

// MARK: - Paste Documentation Here

void metal_atomic64_generate_library(
  const void *float64_library, void **atomic64_library, void **lock_buffer);

#endif /* MetalAtomic64_h */

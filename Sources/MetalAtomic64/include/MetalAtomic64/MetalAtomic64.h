//
//  MetalAtomic64.h
//  
//
//  Created by Philip Turner on 12/15/22.
//

#ifndef MetalAtomic64_h
#define MetalAtomic64_h

// Header for the MetalAtomic64 helper library. This header should be imported
// by CPU code, unlike the header for MetalFloat64. See the Swift source file
// at "Sources/MetalAtomic64/GenerateLibrary.swift" for documentation.

void metal_atomic64_generate_library(
  const void *device, void **library, void **lock_buffer);

#endif /* MetalAtomic64_h */

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

constant size_t globalValue = 0;

struct GlobalConstantValueWrapper {
  constant size_t* originalAddress;
};

struct GlobalDeviceValueWrapper {
  device size_t* finalAddress;
};

struct ValueConverter {
  thread GlobalConstantValueWrapper* original;
  thread GlobalDeviceValueWrapper* convert() {
    return reinterpret_cast<thread GlobalDeviceValueWrapper*>(original);
  }
};

// https://github.com/kokkos/kokkos/blob/master/tpls/desul/include/desul/atomics/Lock_Array_HIP.hpp

// _ZZ24luma_log_sum_to_exposurePU9MTLdevicefRU11MTLconstantKjPU9MTLdeviceDhS4_RU9MTLdevicebttttE4sums

ALWAYS_INLINE uint MetalFloat64::increment(uint x) {
  GlobalConstantValueWrapper originalWrapper{ &globalValue };
  ValueConverter converter{ &originalWrapper };
  thread GlobalDeviceValueWrapper* finalWrapper = converter.convert();
  
  device size_t* finalAddress = finalWrapper[0].finalAddress;
  
  finalAddress[0] += 5;
  finalAddress[0] += 5;
  
  return x + finalAddress[0];
}

# Metal Float64

> Still in the planning stage - this is not a finished library!

Emulating double-precision arithmetic on Apple GPUs, with full IEEE compliance. Based on theoretical estimates, additions and multiplications will have 1/32-1/64 the throughput of their 32-bit counterparts. This is the same throughput ratio as native FP64 on recent NVIDIA GPUs.

MetalFloat64 runs fastest on Apple silicon, although it also runs on Intel Macs. For AMD GPUs with hardware double precision, OpenCL provides better performance for FP64-heavy workloads. For Intel GPUs, FP64 emulation will often make GPU slower than multicore CPU, even when 90% of the compute workload is FP32.

The source code compiles into a Metal dynamic library and a header, which other applications can utilize for double-precision arithmetic. Some FP64 operations can be fully inlined for maximum ALU performance, but others are so large they would bloat the client executable. To address this problem, larger functions invoke function calls into the Metal dynamic library. If possible, clients should operate on multiple floats at a time (e.g. `double2`, `double3`, `double4`). The vectorized function variants minimize binary size and amortize the overhead of function calls.

Since MetalFloat64 requires function pointers and Metal dynamic libraries, it only runs on Apple6 family or newer GPUs. This includes the A13 Bionic and all other Apple GPUs that support the Metal 3 feature set. For Intel Macs, it runs on all devices supporting macOS Ventura.

## Theory

[Turing completeness:](https://en.wikipedia.org/wiki/Turing_completeness) any Turing-complete computer can emulate another Turing-complete computer, given enough time and memory.

Imagine a 1-bit nanomechanical computer with 1000 logic gates, as small as physics allows. It has 1 KB RAM and 100 KB disk. All of this fits within a 200-nanometer sphere - roughly as large as a virus - while being duplicated 5 times for radiation hardness. The read-only storage systems form five spirals that gradually twist around the central axis. They turn 180 degrees azimuthally from bottom to top, halting just before reaching the poles. These replicas form an "outer mantle" - geometrically as distant as possible, preventing a cosmic ray from destroying the same component in three copies at once.

The inner core reaches from zero to half the radius. It contains a shared, radiation-hardened clock, and bidirectional communication channels to each computer and storage subsystem. The core signals sensors and actuators whenever 3 replicas produce the same output. The I/O signals travel along both poles and penetrate the crust, a nanometers-thick artificial mitochondrion. The computing system can control a medical robot that travels through the capillaries, then enters any cell in the human body. It performs life-saving surgery with molecular precision and zero collateral damage.

Notice the specs. This thing has less logic gates than the Intel 4004 had transistors. It clocks at 100 MHz and streams 10^4-10^5 bits/second from onboard sensors. That is over 1000 elementary operations for each bit. The oxyglucose engine provides 1 trillionth of a watt of power, expending ~1000 kT every operation. Notice another design aspect: read-only storage dominates the volume. Executable sizes range in several kilobytes. It took the greater part of a year to settle on this design.

---

Even with ridiculously few hardware capabilities, the nanobot can multiply two double-precision numbers. Doing so takes something on the order of 64x64 clock cycles, 40 microseconds, 4 million kT. However, the greatest bottleneck is executable size. Transferring data from storage tapes to the onboard instruction cache incurs severe latency.

This may be an extreme proof-of-concept, but even a 1-bit Turing complete computer can perform 64-bit math. The Apple GPU has more capabilities than a nanocomputer, letting it emulate FP64 with many fewer instructions. Hardware double precision is not needed. In fact, software approaches have the same performance as native FP64 on AMD RDNA 3 and Nvidia Ampere.

## Usage

Compile the Metal library using `build.sh`, then run the test suite.

```bash
bash build.sh
swift test
```

Locate `.build/MetalFloat64` inside the repo's directory. That folder contains the headers and dynamic library.

```bash
ls .build/MetalFloat64/usr/lib
# Expected:
# libMetalAtomic64.dylib
# libMetalAtomic64.metallibsym
# libMetalFloat64.metallib
# libMetalFloat64.metallibsym

ls .build/MetalFloat64/usr/include
# Expected:
# metal_float64
# MetalAtomic64/MetalAtomic64.h

ls .build/MetalFloat64/usr/placeholders
# Expected:
# libMetalAtomic64.metallib
```

TODO: Instructions for linking the library from command-line, and how to use when compiling sources at runtime. Make a CPU library for encapsulating the Float64 metallibs (only for SwiftPM) and decoding reduced-precision types on the host. Set the call stack depth in your compute pipelines to X amount.

```metal
// Include MetalFloat64 after the Metal Standard Library.
#include <metal_stdlib>
#include <metal_float64>
using namespace metal;
```

TODO: How to initialize the libMetalAtomic64. Warn that you must call `useResource(_:usage:)` on the lock buffer, otherwise half of the GPU will freeze and (a) force the user to restart their computer or (b) silently consume 1/2 the GPU's maximum TDP in the background until a restart.

```swift
// Initialize libMetalAtomic64 from Swift.

```

```c
// Initialize libMetalAtomic64 from C/C++.

```

This library redefines the `double` keyword using a compiler macro, making it legal to use in MSL. The keyword is a typealias of one of the precisions below, which can be chosen through a compiler flag. The compiler flag you easily switch an entire code base to a different precision, and see how it affects performance. Vectorized variants of underlying precisions use `vec<float64_t, 2>` syntax. The keywords `double2`, `double3`, and `double4` are redefined as typealiases of such vectors.

- `float64_t` - IEEE 64-bit floating point with 11 bits exponent and 53 bits mantissa, compatible with CPU. Throughput ratio is ~1:60-80 (FMA), ~1:25 (ADD) compared to FP32.
- `float59_t` - GPU-friendly format with 15 bits exponent and 48 bits mantissa, one bit wasted. Must be converted to/from FP64 on the CPU. Throughput ratio is ~1:35-40 (FMA), ~1:15 (ADD) compared to FP32.
- `float43_t` - GPU-friendly format with 15 bits exponent and 32 bits mantissa, 17 bits wasted. Must be converted to/from FP64 on the CPU. Throughput ratio is ~1:25-30 (FMA), ~1:10 (ADD) compared to FP32.
- The lower precisions always round ties to zero, do not support denormals, and any instance of INF or NAN produces undefined behavior.

TODO: `float32_t` consuming 8 bytes for validation, `float32x2_t` for double-single approach.

## Features

The initial implementation of this library may only support 64-bit add, multiply, and FMA. More complex math functions may roll out later, including division and square root, then finally transcendentals. Complex functions will only be available through function calls. The library will also provide trivial operations like absolute value and negate. These are so small they only occur through inlining.

Furthermore, the library will emulate 64-bit integer atomics by randomly assigning locks to a certain memory address. The client must allocate a lock buffer, then enter it when loading their GPU binary at runtime. Inside MetalAtomic64, a carefully selected series of 32-bit atomics performs a load, store, or cmpxchg without data races. i64/u64/f64 atomics will be implemented on top of these primitives, matching the capabilities of other data types in the MSL specification. Atomics will only be available through function calls.

Small matrix types, such as `double4x4`, are not yet implemented. These have little utility, but implementing them requires significant effort. Users can perform matrix multiplications by multiplying each column of the matrix separately. Regarding vector types, `vec<double, N>` has a quirk that differentiates it from `vec<float, N>`:

```metal
float3 fvector = ...;
double3 dvector = ...;

// Legal:
fvector = float3(fvector.xyz);
dvector = double3(dvector.xyz);
fvector = fvector.xyz;
dvector = dvector.xyz;

// Legal:
fvector = float3(fvector.xyz).xyz;
dvector = double3(dvector.xyz).xyz;
fvector = (fvector.xyz).xyz;

// Illegal:
dvector = (dvector.xyz).xyz;
// Workaround: cast to `double3` before swizzling again
```

## Attribution

This project uses ideas from [SoftFloat](https://github.com/ucb-bar/berkeley-softfloat-3) and [LLVM](https://github.com/llvm/llvm-project/blob/2e999b7dd1934a44d38c3a753460f1e5a217e9a5/compiler-rt/lib/builtins/fp_lib.h) to emulate IEEE-compliant FP64 math through 32-bit integer operations.

The library header duplicates parts of the Metal Standard Library, in order to create a public API for `double` that matches `float`. Locations of copied code are not explicitly outlined, so assume any `.h` file contains such code. Apple owns the copyright to all instances of copied code.

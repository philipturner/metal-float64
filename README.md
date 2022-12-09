# Metal Float64

> Still in the planning stage - this is not a finished library!

Emulating double-precision arithmetic on Apple GPUs, with full IEEE compliance. Based on theoretical estimates, additions and multiplications will have 1/32-1/64 the throughput of their 32-bit counterparts. This is the same throughput ratio as native FP64 on recent NVIDIA GPUs.

This library is optimized for Apple silicon, although it technically runs on x86 Macs. For AMD GPUs with hardware double precision, use OpenCL instead for maximum performance. For Intel GPUs, use the CPU if most of the compute workload is FP64.

The source code compiles into a Metal dynamic library and a header, which other applications can utilize for double-precision arithmetic. It must be a Metal dynamic library to use function calls, because code would become extremely bloated otherwise. This library provides vectorized versions of each function (up to 4-wide) so that clients can amortize the overhead of calling into functions.

Since MetalFloat64 requires function pointers and Metal dynamic libraries, it only runs on Apple6 family or newer GPUs. This includes the A13 Bionic and all other Apple GPUs that support the Metal 3 feature set. For x86 Macs, it runs on all devices supporting macOS Ventura.

## Usage

Compile the Metal library using `build.sh`, then run the test suite.

```
bash build.sh
swift test
```

Locate `.build/MetalFloat64` inside the repo's directory. That folder contains the headers and dynamic library.

```
ls .build/MetalFloat64/usr/lib
ls .build/MetalFloat64/usr/include
# Expected output:
# libMetalFloat64.metallib  libMetalFloat64.metallibsym
# MetalFloat64.h
```

TODO: Instructions for linking the library from command-line, and how to use when compiling sources at runtime

Precisions:
- `float64_t` - IEEE 64-bit floating point with 11 bits exponent and 53 bits mantissa, compatible with CPU. Throughput ratio is ~1:60-80 (FMA), ~1:25 (ADD) compared to FP32.
- `float59_t` - GPU-friendly format with 15 bits exponent and 48 bits mantissa, one bit wasted. Must be converted to/from FP64 on the CPU. Throughput ratio is TODO (FMA), ~1:15 (ADD) compared to FP32.
- `float43_t` - GPU-friendly format with 15 bits exponent and 32 bits mantissa, 17 bits wasted. Must be converted to/from FP64 on the CPU. Throughput ratio is ~1:25-30 (FMA), ~1:10 (ADD) compared to FP32.
- The lower precisions always round ties to zero, do not support denormals, and any arithmetic operator accepting INF or NAN will have undefined behavior. If any of these drawbacks causes precision issues for your use case, please leave an issue in this repository. I can create a special compiler option to enable some of this behavior. <!-- If you are experiencing significant drift toward zero, a compiler option can enable RTE for MUL and the multiply step in FMA. This will harm performance by ~10%. -->

This library redefines the `double` keyword using a compiler macro, making it legal to use in MSL. The keyword is associated with one of the extended precisions, which can be chosen through a compiler flag. This lets you easily switch an entire code base to a different precision, and see how it affects performance.

Vectorized functions of `double2`, `double3`, and `double4` are also redefined, along with vectorized functions of each extended precision.

## Features

The initial implementation of this library may only support 64-bit add, multiply, and FMA. More complex math functions may roll out later, including division and transcendentals. The library could also make fully inlined trivial operations like absolute value and negate, or permit fusing them with a complex 64-bit operation.

Other features:
- Emulated 64-bit atomics using a randomly assigned lock for each memory address.
- Multiple sub-64-bit precisions to balance performance with accuracy.
- Options to either call into a Metal dynamic library or fully inline the code, depending on tolerance for code bloating.

<!-- 
- SIMD-scoped reductions of `double` that massively reduce the number of function calls. For example, a version of `simdgroup_matrix` usable in a BLAS library.
- 64-bit atomics based on the [Nanite workaround](https://github.com/philipturner/ue5-nanite-macos/tree/main/AtomicsWorkaround). This isn't standards-compliant 64-bit atomics. It operates on a 128-256 bit chunk of memory, but provides 64-bit atomic functionality.
- Repurposing the `fast::` and `precise::` namespaces for inlined (when possible) and non-inlined versions of each function. If not specified, the library will choose one version based on compiler flags and/or heuristics. Choosing `fast::` will not affect precision; only performance. -->

## Attribution

This project uses ideas from [SoftFloat](https://github.com/ucb-bar/berkeley-softfloat-3) to emulate IEEE-compliant FP64 arithmetic using 32-bit integer operations. It optimizes the implementation for SIMD execution, which favors minimizing divergence and branching. This causes a slight overhead in best-case scenarios, but much faster performance in worst-case scenarios.

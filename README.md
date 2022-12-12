# Metal Float64

> Still in the planning stage - this is not a finished library!

Emulating double-precision arithmetic on Apple GPUs, with full IEEE compliance. Based on theoretical estimates, additions and multiplications will have 1/32-1/64 the throughput of their 32-bit counterparts. This is the same throughput ratio as native FP64 on recent NVIDIA GPUs.

This library is optimized for Apple silicon, although it technically runs on x86 Macs. For AMD GPUs with hardware double precision, OpenCL provides better FP64 performance. For Intel GPUs, FP64 emulation will often make GPU slower than multicore CPU, even when 90% of the compute workload is FP32.

The source code compiles into a Metal dynamic library and a header, which other applications can utilize for double-precision arithmetic. Some FP64 operations can be fully inlined for maximum ALU performance, but others are so large they would bloat the client executable. To address this problem, larger functions invoke function calls into the Metal dynamic library. If possible, perform operations on multiple floats at a time (e.g. `double2`, `double3`, `double4`). The vectorized function variants minimize binary size and amortize the overhead of function calls.

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
- `float59_t` - GPU-friendly format with 15 bits exponent and 48 bits mantissa, one bit wasted. Must be converted to/from FP64 on the CPU. Throughput ratio is ~1:35-40 (FMA), ~1:15 (ADD) compared to FP32.
- `float43_t` - GPU-friendly format with 15 bits exponent and 32 bits mantissa, 17 bits wasted. Must be converted to/from FP64 on the CPU. Throughput ratio is ~1:25-30 (FMA), ~1:10 (ADD) compared to FP32.
- The lower precisions always round ties to zero, do not support denormals, and any arithmetic operator handling INF or NAN will have undefined behavior.

This library redefines the `double` keyword using a compiler macro, making it legal to use in MSL. The keyword is associated with one of the extended precisions, which can be chosen through a compiler flag. This lets you easily switch an entire code base to a different precision, and see how it affects performance.

Vectorized functions of `double2`, `double3`, and `double4` are also redefined, along with vectorized functions of each extended precision.

## Features

The initial implementation of this library may only support 64-bit add, multiply, and FMA. More complex math functions may roll out later, including division and square root, then finally transcendentals. Complex functions will only be available through function calls. The library should also permit trivial operations like absolute value and negate. These are so small they will only be available through inlining.

Furthermore, the library will emulate 64-bit integer atomics by randomly assigning locks to a certain memory address. The client must allocate a lock buffer, then pass it into the library. At runtime, a carefully selected series of 32-bit atomics performs a load, store, or cmpxchg without data races. i64/u64/f64 atomics will be implemented on top of these primitives, matching the capabilities of other data types in the MSL specification. Atomics will only be available through function calls.

## Attribution

This project uses ideas from [SoftFloat](https://github.com/ucb-bar/berkeley-softfloat-3) and [LLVM](https://github.com/llvm/llvm-project/blob/2e999b7dd1934a44d38c3a753460f1e5a217e9a5/compiler-rt/lib/builtins/fp_lib.h) to emulate IEEE-compliant FP64 arithmetic through 32-bit integer operations.

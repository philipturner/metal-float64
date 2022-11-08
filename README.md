# Metal Float64

> Still in the planning stage - this is not a finished library!

Emulating double-precision arithmetic on Apple GPUs, with full IEEE compliance. Based on theoretical estimates, additions and multiplications will have 1/32-1/64 the throughput of their 32-bit counterparts. This is the same throughput ratio as native FP64 on recent NVIDIA GPUs.

This library is optimized for Apple silicon, although it technically runs on x86 Macs. For AMD GPUs with hardware double precision, use OpenCL instead for maximum performance. For Intel GPUs, use the CPU if most of the compute workload is FP64.

The source code compiles into a Metal dynamic library and a header, which other applications can utilize for double-precision arithmetic. It must be a Metal dynamic library to use function calls, because code would become extremely bloated otherwise. This library provides vectorized versions of each function (up to 4-wide) so that clients can amortize the overhead of calling into functions.

Since this requires function pointers and Metal dynamic libraries, it only runs on Apple6 family or newer GPUs. This includes the A13 Bionic and all other Apple GPUs that support the Metal 3 feature set. For x86 Macs, it runs on all devices supporting macOS Ventura.

## Features

The initial implementation of this library may only support 64-bit add, multiply, and FMA. More complex math functions may roll out later, including division and transcendentals. The library could also make fully inlined trivial operations like absolute value and negate, or permit fusing them with a complex 64-bit operation.

## Attribution

This project uses ideas from [SoftFloat](https://github.com/ucb-bar/berkeley-softfloat-3) to emulate IEEE-compliant FP64 arithmetic using 32-bit integer operations. It optimizes the implementation for SIMD execution, which favors minimizing divergence and branching. This creates slightly more overhead in best-case scenarios, but ~10x faster performance in worst-case scenarios.

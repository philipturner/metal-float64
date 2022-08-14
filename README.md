# Metal Float64

Emulating double-precision arithmetic on Apple GPUs, with full IEEE compliance. Based on initial estimates, additions and multiplications will have 1/64 the throughput of their 32-bit counterparts. This is the same throughput ratio as native FP64 on recent NVIDIA GPUs.

This only runs on Apple silicon. x86 Macs have either AMD or Intel GPUs, which have hardware double precision. For these devices, use OpenCL on macOS (if it permits double precision) or switch to Windows with Bootcamp.

This project will produce a Metal dynamic library and a header, which other applications can utilize for double-precision arithmetic. It must be a Metal dynamic library to use function calls, because code would become extremely bloated otherwise. This library provides vectorized versions of each function (up to 4-wide) so that clients can amortize the overhead of calling into functions.

Since this requires function pointers and Metal dynamic libraries, it only runs on Apple6 family or newer GPUs. This includes the A13 Bionic and all other Apple GPUs that support the Metal 3 feature set.

## Attribution

This project uses ideas from [SoftFloat](https://github.com/ucb-bar/berkeley-softfloat-3) to emulate IEEE-compliant FP64 arithmetic using 64-bit integer operations. It optimizes the implementation for SIMD execution, which favors minimizing divergence and branching. This creates slightly more overhead in best-case scenarios, but ~10x faster performance in worst-case scenarios.

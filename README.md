# Metal Float64

Emulating double-precision arithmetic on Apple GPUs.

This only runs on Apple silicon. x86 Macs have either AMD or Intel GPUs, which have hardware double precision. For these devices, use OpenCL on macOS (if it permits double precision) or switch to Windows with Bootcamp.

This project will produce a Metal dynamic library and a header, which other applications can utilize for double-precision arithmetic. It must be a Metal dynamic library to use function calls, because code would become extremely bloated otherwise. This library provides vectorized versions of each function (up to 4-wide) so that clients can amortize the overhead of calling into functions.

Since this requires function pointers and Metal dynamic libraries, it only runs on Apple6 family or newer GPUs. This includes the A13 Bionic and all other Apple GPUs that support the Metal 3 feature set.

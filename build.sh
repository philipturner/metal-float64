#!/bin/bash
# Script for compiling and packaging the Metal dynamic library.
# This also generates and updates the test suite's resources.

# Parse command-line arguments.
BUILD_SDK="macosx"
if [[ $# != 0 ]]; then
  invalid_input=false

  if [[ $# != 2 || $1 != "--platform" ]]; then
    invalid_input=true
  fi
  if [[ $invalid_input == false ]]; then
    if [[ $2 == "macOS" ]]; then
      BUILD_SDK="macosx"
    elif [[ $2 == "iOS" ]]; then
      BUILD_SDK="iphoneos"
    elif [[ $2 == "tvOS" ]]; then
      BUILD_SDK="appletvos"
    else
      invalid_input=true
    fi
  fi

  if [[ $invalid_input == true ]]; then
    echo "Usage: build.sh [--platform=[macOS, iOS, tvOS]; default=\"macOS\"]"
    exit -1
  fi
fi

# 'build' directory aliases '.build' from SwiftPM. It is recognized by the
# '.gitignore', so you won't push unwanted files to the Git repository.
if [[ ! -e ".build" ]]; then
  mkdir ".build"
fi
SWIFT_PACKAGE_DIR=$(pwd)
BUILD_DIR="${SWIFT_PACKAGE_DIR}/.build"
cd ".build"

# Create folder for packaging the library.
cp -r "${SWIFT_PACKAGE_DIR}/Sources/MetalFloat64" $BUILD_DIR
cd "MetalFloat64"
PACKAGED_LIBRARY_DIR=$(pwd)

# Switch to 'lib' before generating relative source file paths.
if [[ ! -e "lib" ]]; then
  mkdir "lib"
fi
cd "lib"

# Fuse the headers into single file.
swift "${SWIFT_PACKAGE_DIR}/build.swift" \
  $PACKAGED_LIBRARY_DIR \
  "--merge-float64-headers"

# Rename "MetalFloat64/MetalFloat64.h" to "metal_float64".
mv "${PACKAGED_LIBRARY_DIR}/include/MetalFloat64/MetalFloat64.h" \
  "${PACKAGED_LIBRARY_DIR}/include/metal_float64"

# Compile the library.
# - Uses '-Os' to encourage force-noinlines to work correctly.
# - '@rpath' causes a massive headache; use '@loader_path' instead. This means
#   'libMetalFloat64' must reside in the same directory as any clients.
FLOAT64_SOURCE_FILES=$(find ../src -name \*.metal)
xcrun -sdk $BUILD_SDK metal \
  $FLOAT64_SOURCE_FILES \
  -o "libMetalFloat64.metallib" \
  -I "../include" \
  -Os \
  -dynamiclib \
  -frecord-sources=flat \
  -fvisibility=hidden \
  -install_name "@loader_path/libMetalFloat64.metallib"

# Compile MetalAtomic64 for CPU and GPU.
ATOMIC64_SOURCE_DIR="${SWIFT_PACKAGE_DIR}/Sources/MetalAtomic64"
xcrun -sdk $BUILD_SDK metal \
  "${ATOMIC64_SOURCE_DIR}/src/Atomic.metal" \
  -o "libMetalAtomic64.metallib" \
  -L "../lib" \
  -lMetalFloat64 \
  -Os \
  -DMETAL_ATOMIC64_PLACEHOLDER \
  -dynamiclib \
  -frecord-sources=flat \
  -install_name "@loader_path/libMetalAtomic64.metallib"

# Move MetalAtomic64 metallib somewhere that clearly indicates it's a dummy.
if [[ ! -e "../placeholders" ]]; then
  mkdir "../placeholders"
fi
mv -f "libMetalAtomic64.metallib" "../placeholders/libMetalAtomic64.metallib"

# Encapsulate the directory that builds this, so we can delete any output
# files we don't want.
mkdir tmp && cd tmp
swift "${SWIFT_PACKAGE_DIR}/build.swift" \
  "${SWIFT_PACKAGE_DIR}/Sources/MetalAtomic64" \
  "--embed-atomic64-sources"
swiftc \
  "${ATOMIC64_SOURCE_DIR}/src/GenerateLibrary.swift" \
  -Onone \
  -DMETAL_ATOMIC64_C_INTERFACE \
  -emit-module \
  -emit-library \
  -module-name "MetalAtomic64"
mv "libMetalAtomic64.dylib" "../libMetalAtomic64.dylib"
cd ../
rm -rf tmp

# Copy the C header to the includes directory.
cp -r "${ATOMIC64_SOURCE_DIR}/include/MetalAtomic64" "../include/MetalAtomic64"

# Compile the test library.
TEST_FILES=$(find ../tests -name \*.metal)
xcrun -sdk $BUILD_SDK metal \
  $TEST_FILES \
  -o "Tests.metallib" \
  -I "../include" \
  -L "../lib" \
  -L "../placeholders" \
  -lMetalFloat64 \
  -lMetalAtomic64 \

# Copy libraries into test resources
resource_copy_src=${PACKAGED_LIBRARY_DIR}
resource_copy_dst="${SWIFT_PACKAGE_DIR}/Tests/MetalFloat64Tests/Resources"
cp -r "${resource_copy_src}/lib/libMetalFloat64.metallib" \
      "${resource_copy_dst}/libMetalFloat64.metallib"
cp -r "${resource_copy_src}/lib/Tests.metallib" \
      "${resource_copy_dst}/Tests.metallib"

# Prepare "usr" directory.
if [[ -e "${PACKAGED_LIBRARY_DIR}/usr" ]]; then
  # `mv` fails if something already exists here.
  rm -r "${PACKAGED_LIBRARY_DIR}/usr"
fi
mkdir "${PACKAGED_LIBRARY_DIR}/usr"

# Finish packaging library
rm -r "${PACKAGED_LIBRARY_DIR}/lib/Tests.metallib"
rm -r "${PACKAGED_LIBRARY_DIR}/src"
rm -r "${PACKAGED_LIBRARY_DIR}/tests"
mv -f "${PACKAGED_LIBRARY_DIR}/include" "${PACKAGED_LIBRARY_DIR}/usr"
mv -f "${PACKAGED_LIBRARY_DIR}/lib" "${PACKAGED_LIBRARY_DIR}/usr"
mv -f "${PACKAGED_LIBRARY_DIR}/placeholders" "${PACKAGED_LIBRARY_DIR}/usr"

start_yellow="$(printf '\e[0;33m')"
end_yellow="$(printf '\e[0m')"
colorized_package_path="${start_yellow}${PACKAGED_LIBRARY_DIR}${end_yellow}"
echo "MetalFloat64 packaged at: ${colorized_package_path}"

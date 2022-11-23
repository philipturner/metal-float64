#!/bin/bash
# Script for compiling and packaging the Metal dynamic library.
# This also generates and updates the test suite's resources.
# TODO: Make a test metallib that's linked against the build product.

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

# Compile the library.
SOURCE_FILES=$(find ../src -name \*.metal)
LIBRARY_NAME="libMetalFloat64"
xcrun -sdk $BUILD_SDK metal \
  $SOURCE_FILES \
  -I "../include" \
  -o "${LIBRARY_NAME}.metallib" \
  -dynamiclib \
  -frecord-sources=flat \
  -fvisibility=hidden \
  -install_name "@loader_path/${LIBRARY_NAME}.metallib" \

start_yellow="$(printf '\e[0;33m')"
end_yellow="$(printf '\e[0m')"
colorized_package_path="${start_yellow}${PACKAGED_LIBRARY_DIR}${end_yellow}"
echo "Library packaged at: ${colorized_package_path}"

# Copy package into test resources
resource_copy_src=${PACKAGED_LIBRARY_DIR}
resource_copy_dst="${SWIFT_PACKAGE_DIR}/Tests/MetalFloat64Tests/Resources"
cp -r $resource_copy_src $resource_copy_dst

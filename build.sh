#!/bin/bash
# Script for compiling and packaging the Metal dynamic library.

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
  mkdir .build
fi
PACKAGE_DIR=$(pwd)
BUILD_DIR="${PACKAGE_DIR}/.build"
cd .build

# Copy Metal source files.
SOURCE_DIR="${BUILD_DIR}/MetalFloat64"
cp -r "${PACKAGE_DIR}/Sources/MetalFloat64" $SOURCE_DIR
SOURCE_FILES=$(find . -name \*.metal)

# Compile the library.
# TODO: Determine whether using '@rpath' instead of '@loader_path' causes problems.
LIBRARY_NAME="MetalFloat64"
xcrun -sdk $BUILD_SDK metal $SOURCE_FILES \
  -I ./MetalFloat64/include \
  -o "lib${LIBRARY_NAME}.metallib" \
  -dynamiclib \
  -frecord-sources=flat \
  -fvisibility=hidden \
  -install_name "@rpath/lib${LIBRARY_NAME}.metallib" \

echo $(ls)

# Create folder structure and copy library.

# Copy headers to destination.

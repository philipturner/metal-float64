// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MetalFloat64",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .tvOS(.v16)
  ],
  products: [],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.

        // TODO: Use runtime compilation instead so I can disable fast math and
        // function inlining, without creating an Xcode project. Alternatively,
        // compile these using the command-line Metal compiler so that I can use
        // headers properly.
        //
        // End goal: a Metal dynamic library that external applications can call
        // into. Up to 4-wide vectorized operations to amortize function calling
        // overhead, decide on a maximum call stack depth.
        //
        // Library name: libMetalFloat64.metallib
    .testTarget(
      name: "MetalFloat64Tests",
      dependencies: [],
      resources: [
        .copy("Resources/")
      ]),
  ]
)

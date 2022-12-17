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
  products: [
    .library(
      name: "MetalAtomic64",
      type: .dynamic,
      targets: ["MetalAtomic64"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "MetalAtomic64",
      exclude: [
        // Xcode will not let us include "src/Atomic.metal" as a typical
        // resource. It always invokes the Metal compiler on the file. To work
        // around this, we embed Metal sources into the original Swift file.
        // The build script embeds the sources automatically.
        "src/Atomic.metal",
      ],
      sources: [
        "src/GenerateLibrary.swift",
      ]),
    .testTarget(
      name: "MetalFloat64Tests",
      dependencies: ["MetalAtomic64"],
      resources: [
        .copy("Resources/")
      ]),
  ]
)

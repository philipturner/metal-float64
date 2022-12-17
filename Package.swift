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
      resources: [
        .copy("src/Atomic.metal")
      ],
      // TODO: Remove this after debugging; we do not want to expose this to the
      // Swift package API.
      swiftSettings: [.define("METAL_ATOMIC64_C_INTERFACE")]),
    .testTarget(
      name: "MetalFloat64Tests",
      dependencies: [],
      resources: [
        .copy("Resources/")
      ]),
  ]
)

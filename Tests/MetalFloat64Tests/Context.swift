//
//  Context.swift
//  
//
//  Created by Philip Turner on 11/22/22.
//

import Metal
import MetalAtomic64

struct Context {
  static let global = Context()
  
  var device: MTLDevice
  var library: MTLLibrary
  var commandQueue: MTLCommandQueue
  
  // List of pipelines, identified by their name in shader code.
  var pipelines: [String: MTLComputePipelineState] = [:]
  
  private var float64_library: MTLDynamicLibrary
  private var atomic64_library: MTLDynamicLibrary
  var lock_buffer: MTLBuffer
  
  init() {
    self.device = MTLCreateSystemDefaultDevice()!
    self.commandQueue = device.makeCommandQueue()!
    
    // Fetch libraries and library paths.
    let testLibraryPath = fetchPath(forResource: "Tests", ofType: "metallib")
    let testLibraryURL = URL(filePath: testLibraryPath)
    let librariesURL = testLibraryURL.deletingLastPathComponent()
    let float64LibraryURL = librariesURL
      .appending(component: "libMetalFloat64.metallib")
    self.float64_library = try! device
      .makeDynamicLibrary(url: float64LibraryURL)
    (self.atomic64_library, self.lock_buffer) = metal_atomic64_generate_library(float64_library)
    
    // Write the atomics library so you can load the test library.
    let atomic64LibraryURL = librariesURL
      .appending(component: "libMetalAtomic64.metallib")
    try! self.atomic64_library.serialize(to: atomic64LibraryURL)
    self.library = try! device.makeLibrary(URL: testLibraryURL)
    
    // Cannot contain vertex, fragment, or ray tracing functions.
    for name in library.functionNames {
      let function = library.makeFunction(name: name)!
      let desc = MTLComputePipelineDescriptor()
      desc.computeFunction = function
      
      // Set the max call stack depth (default: 1).
      // Using Metal Shader Validation, you can detect stack overflows.
      desc.maxCallStackDepth = 5
      
      let pipeline = try! device.makeComputePipelineState(descriptor: desc, options: [], reflection: nil)
      self.pipelines[name] = pipeline
    }
  }
  
  // Creates and commits the command buffer for you.
  func withCommandBuffer<R>(
    synchronized: Bool = true,
    _ closure: (MTLCommandBuffer) throws -> R
  ) rethrows -> R {
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let output = try closure(commandBuffer)
    commandBuffer.commit()
    
    if synchronized {
      commandBuffer.waitUntilCompleted()
    }
    return output
  }
  
  // Creates and ends the compute encoder for you.
  func withComputeEncoder<R>(
    synchronized: Bool = true,
    _ closure: (MTLComputeCommandEncoder) throws -> R
  ) rethrows -> R {
    return try withCommandBuffer(synchronized: synchronized) { commandBuffer in
      let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
      let output = try closure(computeEncoder)
      computeEncoder.endEncoding()
      
      return output
    }
  }
}

import XCTest

final class AtomicTests: XCTestCase {
  func testAtomicsCompile() throws {
    // Allocate input buffers
    let device = Context.global.device
    let inputBuffer = device.makeBuffer(length: 16)!
    let outputBuffer = device.makeBuffer(length: 16)!
    let inputContents = inputBuffer.contents().assumingMemoryBound(to: Int32.self)
    inputContents[0] = 4;
    
    for _ in 0..<2 {
      Context.global.withComputeEncoder { encoder in
        let pipeline = Context.global.pipelines["testAtomicsCompile"]!
        encoder.setComputePipelineState(pipeline)
        
        encoder.setBuffer(inputBuffer, offset: 0, index: 0)
        encoder.setBuffer(outputBuffer, offset: 0, index: 1)
        encoder.dispatchThreads(
          MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
      }
      
      // Check output buffer.
      let outputContents = outputBuffer.contents().assumingMemoryBound(to: Int32.self)
      print(outputContents[0])
    }
  }
}

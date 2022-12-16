import XCTest

final class MetalFloat64Tests: XCTestCase {
  func testResourcesExist() throws {
    _ = fetchPath(forResource: "README", ofType: "md")
    _ = fetchPath(forResource: "libMetalFloat64", ofType: "metallib")
    _ = fetchPath(forResource: "Tests", ofType: "metallib")
  }
  
  // Reference function
//  func testFullScreenColor() throws {
//    // Allocate input buffer
//    let device = Context.global.device
//    let inputBuffer = device.makeBuffer(length: 16)!
//    let inputContents = inputBuffer.contents()
//      .assumingMemoryBound(to: SIMD4<Float>.self)
//
//    // Initialize input buffer
//    inputContents[0] = [1, 2, 3, 4]
//
//    Context.global.withComputeEncoder { encoder in
//      let pipeline = Context.global.pipelines["testFullScreenColor"]!
//      encoder.setComputePipelineState(pipeline)
//
//      let unusedBuffer = device.makeBuffer(length: 16)
//      encoder.setBuffer(unusedBuffer, offset: 0, index: 0)
//      encoder.setBuffer(inputBuffer, offset: 0, index: 1)
//      encoder.dispatchThreads(
//        MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
//    }
//
//    // Check input buffer
//    XCTAssertEqual(inputContents[0], [1, 2, 3, 0])
//  }
//
//
}

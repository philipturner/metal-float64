import XCTest

// This test suite is sourced from:
// https://github.com/philipturner/ue5-nanite-macos/tree/main/AtomicsWorkaround
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
    }
  }
  
  // All atomic fetch-modify functions should be testable, because their result
  // is indepedent of the order of operands.
  func testAtomicOperations() throws {
    let device = Context.global.device
    #if os(macOS)
    let bufferStorageMode: MTLResourceOptions = .storageModeManaged
    #else
    let bufferStorageMode: MTLResourceOptions = .storageModeShared
    #endif
    let outBuffer = device.makeBuffer(
      length: Configuration.outBufferSize * 8, options: bufferStorageMode)!
    let errorsBuffer = device.makeBuffer(
      length: Configuration.numThreads * 8, options: bufferStorageMode)!
    let randomData = generateRandomData()
    
    func testAtomicOperation<T: Numeric>(
      type: T.Type,
      _ pipeline: String,
      _ nextPartialResult: (T, T) -> T
    ) {
      var _commandBuffer: MTLCommandBuffer?
      Context.global.withCommandBuffer(synchronized: false) { commandBuffer in
        let blitEncoder1 = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder1.synchronize(resource: randomData)
        blitEncoder1.synchronize(resource: outBuffer)
        blitEncoder1.endEncoding()
        
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        let pipeline = Context.global.pipelines[pipeline]!
        encoder.setComputePipelineState(pipeline)
        encoder.useResource(Context.global.lock_buffer, usage: [.read, .write])
        
        var _numItemsPerThread: UInt32 = .init(Configuration.itemsPerThread)
        encoder.setBytes(&_numItemsPerThread, length: 4, index: 0)
        encoder.setBuffer(randomData, offset: 0, index: 1)
        encoder.setBuffer(outBuffer, offset: 0, index: 2)
        encoder.setBuffer(errorsBuffer, offset: 0, index: 3)
        encoder.dispatchThreads(
          MTLSizeMake(Configuration.numThreads, 1, 1),
          threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
        encoder.endEncoding()
        
        let blitEncoder2 = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder2.synchronize(resource: randomData)
        blitEncoder2.synchronize(resource: outBuffer)
        blitEncoder2.endEncoding()
        
        _commandBuffer = commandBuffer
      }
      
      let expected = generateExpectedResults(
        randomData: randomData, nextPartialResult)
      _commandBuffer!.waitUntilCompleted()
      print("Cmdbuf time: \((_commandBuffer!.gpuEndTime - _commandBuffer!.gpuStartTime) * 1e6)")
      validateResults(
        randomData: randomData, expected: expected, actual: outBuffer)
      
      let errors = errorsBuffer.contents().assumingMemoryBound(to: UInt64.self)
      var firstErrorIndex = -1
      var firstError = 0
      for i in 0..<Configuration.numThreads {
        if errors[i] != 0 {
          firstErrorIndex = i
          break
        }
      }
      if firstErrorIndex != -1 {
        XCTAssert(false, "Thread \(firstErrorIndex) produced error code \(firstError).")
      }
    }
    
    testAtomicOperation(type: UInt64.self, "testAtomicAdd") {
      $0 + $1
    }
  }
}

private struct RandomData {
  var index: UInt32
  var value: UInt64
}

// TODO: Bump this up to 10,000 threads/10,000 buffer size.
private struct Configuration {
  static let itemsPerThread: Int = 10
  static let numThreads: Int = 10000
  static var numItems: Int { itemsPerThread * numThreads }
  static let outBufferSize: Int = 2007
}


// From https://stackoverflow.com/a/71490330:
private struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    init(seed: Int) { srand48(seed) }
    func next() -> UInt64 { return UInt64(drand48() * Double(UInt64.max)) }
}

private func generateRandomData() -> MTLBuffer {
  let device = Context.global.device
  let bufferSize = Configuration.numItems * MemoryLayout<RandomData>.stride
  #if os(macOS)
  let buffer = device.makeBuffer(
    length: bufferSize, options: .storageModeManaged)!
  #else
  let buffer = device.makeBuffer(
    length: bufferSize, options: .storageModeShared)!
  #endif
  
  let bufferContents = buffer.contents()
    .assumingMemoryBound(to: RandomData.self)
  var generator = RandomNumberGeneratorWithSeed(seed: 42)
  for i in 0..<Configuration.numItems {
    let index = UInt32.random(
      in: 0..<UInt32(Configuration.outBufferSize), using: &generator)
    let value = UInt64.random(
      in: 0..<UInt64(1 << 50), using: &generator)
    bufferContents[i] = RandomData(index: index, value: value)
  }
  return buffer
}

private func generateExpectedResults<T: Numeric>(
  randomData: MTLBuffer,
  _ nextPartialResult: (T, T) -> T
) -> [T] {
  precondition(MemoryLayout<T>.stride == 8, "Not stride-8 data type.")
  
  var output = Array<T>(repeating: 0, count: Configuration.outBufferSize)
  let randomDataContents = randomData.contents()
    .assumingMemoryBound(to: RandomData.self)
  for i in 0..<Configuration.numItems {
    let item = randomDataContents[i]
    let previous = output[Int(item.index)]
    let value = unsafeBitCast(item.value, to: T.self)
    let next = nextPartialResult(previous, value)
    output[Int(item.index)] = next
  }
  
  return output
}

private func validateResults<T: Numeric>(
  randomData: MTLBuffer,
  expected: [T],
  actual: MTLBuffer
) {
  let _randomData = randomData.contents().assumingMemoryBound(to: RandomData.self)
  let actualContents = actual.contents().assumingMemoryBound(to: T.self)
  
  var firstFailure: Int = -1
  var succeeded: Bool = true
  for i in 0..<Configuration.outBufferSize {
    if expected[i] != actualContents[i] {
      firstFailure = i
      succeeded = false
      break
    }
  }
  
  if succeeded {
    return
  }
  let lhs = expected[firstFailure]
  let rhs = actualContents[firstFailure]
  XCTAssert(false, """
    Item \(firstFailure) was the first item with unexpected results.
    \(lhs) != \(rhs)
    """)
}

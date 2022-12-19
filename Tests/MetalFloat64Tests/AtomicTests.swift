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
    let randomData = generateScatteredData()
//    let randomData = generateCoalescedData()
    
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
      var firstError: UInt64 = 0
      for i in 0..<Configuration.numThreads {
        if errors[i] != 0 {
          firstErrorIndex = i
          firstError = errors[i]
          break
        }
      }
      if firstErrorIndex != -1 {
        XCTAssert(false, "Thread \(firstErrorIndex) produced error code \(firstError).")
      }
    }
    
    // TODO: Repeat this test with different variations of configuration.
    testAtomicOperation(type: UInt64.self, "testAtomicAdd") {
      $0 + $1
    }
  }
}

private struct RandomData {
  var index: UInt32
  var value: UInt64
}

// If numThreads is 100_000 (1_000_000 operations):
// Machine: M1 Max (32-core, 408 GB/s)
// Bytes potentially transferred/item (32-bit): 24
// Bytes potentially transferred/item (64-bit): 52
// Atomic instructions/op (32-bit): 1
// Atomic instructions/op (64-bit): 8
// 32-bit coalesced:  243 us -> 4.12 GOP/s, 4.12 GIPS, 99 GB/s
// 32-bit scattered:  419 us -> 2.39 GOP/s, 2.39 GIPS, 57 GB/s
// 64-bit coalesced:  824 us -> 1.21 GOP/s, 9.71 GIPS, 63 GB/s
// 64-bit scattered: 2075 us -> 0.48 GOP/s, 3.86 GIPS, 25 GB/s
//
// Perhaps we'd get more GB/s for 32-bit, if there were less items/thread,
// maybe even 1 item/thread. The benchmarks will be run one more time, using
// that idea.
//
// 32-bit coalesced:  139 us -> 7.19 GOP/s,  7.19 GIPS, 173 GB/s
// 32-bit scattered:  385 us -> 2.60 GOP/s,  2.60 GIPS,  62 GB/s
// 64-bit coalesced:  678 us -> 1.47 GOP/s, 11.80 GIPS,  77 GB/s
// 64-bit scattered: 2291 us -> 0.44 GOP/s,  3.49 GIPS,  23 GB/s
// 173 GB/s out of 404 GB/s - that's more like it! 64-bit atomics also performed
// better, at ??? GB/s. The gap between 32-bit and 64-bit has widened from ~50%
// to ~120% in bandwidth utilization. 64-bit is about the same as 32-bit with
// scattered reads.

private struct Configuration {
  static let itemsPerThread: Int = 10
  static let numThreads: Int = 10_000
  static var numItems: Int { itemsPerThread * numThreads }
  static let outBufferSize: Int = 65536 // 60070
}

private func generateScatteredData() -> MTLBuffer {
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
  for i in 0..<Configuration.numItems {
    let index = UInt32.random(in: 0..<UInt32(Configuration.outBufferSize))
    let value = UInt64.random(in: 0..<UInt64(1 << 22))
    bufferContents[i] = RandomData(index: index, value: value)
  }
  return buffer
}

// Generates memory addresses in a way that minimizes lock contention.
private func generateCoalescedData() -> MTLBuffer {
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
  
  // Take random samples to ensure everything's going correctly.
  var threadsWithIndex0 = 0
  var threadsWithIndex37 = 0
  var threadsWithIndex101 = 0
  
  // Simdgroup size is 64 on AMD.
  let gpuName = MTLCreateSystemDefaultDevice()!.name
  var executionWidth = 32
  if gpuName.contains("AMD") || gpuName.contains("RX") || gpuName.contains("Radeon") {
    executionWidth = 64
  }
  
  // Everything is staggered in multiples of `itemsPerThread`.
  // Divide chunks among simdgroups, then redistribute work within simdgroups.
  let chunkSize = Configuration.itemsPerThread * executionWidth
  for i in 0..<Configuration.numItems {
    let chunkID = i / chunkSize
    let idInChunk = i % chunkSize
    let chunkBaseIndex = chunkID * chunkSize
    
    // The first thread's list of indices would be:
    // [0 (i =  0), 32 (i =  1), 64 (i =  2), ...]
    // The second thread's list of indices would be:
    // [1 (i = 10), 33 (i = 11), 65 (i = 12), ...]
    // The last thread's list of indices would be:
    // [31 (i = 310), 63 (i = 311), ...]
    
    let firstListElement = idInChunk / Configuration.itemsPerThread
    let listStride = executionWidth
    let newIDInChunk = firstListElement +
      (idInChunk % Configuration.itemsPerThread) * listStride;
    let newI = newIDInChunk + chunkBaseIndex
    
    if newIDInChunk == 0 {
      threadsWithIndex0 += 1
    } else if newIDInChunk == 37 {
      threadsWithIndex37 += 1
    } else if newIDInChunk == 101 {
      threadsWithIndex101 += 1
    }
    
    precondition(newIDInChunk < chunkSize && newIDInChunk >= 0)
    let wrappedI = UInt32(newI % Configuration.outBufferSize)
    
    _ = UInt32.random(in: 0..<UInt32(Configuration.outBufferSize))
    let value = UInt64.random(in: 0..<UInt64(1 << 22))
    bufferContents[i] = RandomData(index: wrappedI, value: value)
  }
  
  // Check that the number distribution is as expected.
  let numChunksMinimum = Configuration.numItems / chunkSize
  let acceptedRange = (numChunksMinimum / 2)...(numChunksMinimum * 3 / 2)
  precondition(numChunksMinimum >= 20)
  guard acceptedRange.contains(threadsWithIndex0) else {
    fatalError("Something went wrong (0)")
  }
  if chunkSize >= 37 {
    guard acceptedRange.contains(threadsWithIndex37) else {
      fatalError("Something went wrong (37)")
    }
  }
  if chunkSize >= 101 {
    guard acceptedRange.contains(threadsWithIndex101) else {
      fatalError("Something went wrong (101)")
    }
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
    print("Operation succeeded!")
    return
  }
  let lhs = expected[firstFailure]
  let rhs = actualContents[firstFailure]
  XCTAssert(false, """
    Item \(firstFailure) was the first item with unexpected results.
    \(lhs) != \(rhs)
    """)
}

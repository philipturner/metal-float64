import XCTest

final class MetalFloat64Tests: XCTestCase {
  func testResourcesExist() throws {
    _ = fetchPath(forResource: "libMetalFloat64", ofType: "metallib")
    _ = fetchPath(forResource: "Tests", ofType: "metallib")
  }
}

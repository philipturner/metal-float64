import XCTest

final class MetalFloat64Tests: XCTestCase {
  func testMetallibExists() throws {
    _ = fetchPath(forResource: "README", ofType: "md")
    _ = fetchPath(forResource: "libMetalFloat64", ofType: "metallib")
    _ = fetchPath(forResource: "Defines", ofType: "h")
    _ = fetchPath(forResource: "Double", ofType: "metal")
  }
}

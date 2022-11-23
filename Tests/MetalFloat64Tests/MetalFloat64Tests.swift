import XCTest

final class MetalFloat64Tests: XCTestCase {
  func testMetallibExists() throws {
    _ = fetchPath(forResource: "README", ofType: "md")
  }
}

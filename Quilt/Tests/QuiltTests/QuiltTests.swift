import XCTest
@testable import Quilt

final class QuiltTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Quilt().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

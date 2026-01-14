import XCTest

@testable import SwiftyR2

final class SwiftyR2Tests: XCTestCase {

    func testCoreCreationAndSimpleCommand() async throws {
        let core = await R2Core.create()

        let output = await core.cmd("?V")
        XCTAssertFalse(output.isEmpty, "Expected non-empty output from ?V command")
        XCTAssertTrue(
            output.lowercased().contains("radare2"),
            "Expected version output to mention radare2, got: \(output)"
        )
    }
}

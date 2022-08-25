import XCTest
@testable import GitKit

final class GitKitTests: XCTestCase {

	

    func testClibgitImport() throws {
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("GitKitTests/")

		addTeardownBlock {
			try FileManager.default.removeItem(at: tempDir)
		}

		let cloneURL = URL(string: "https://github.com/allotropeinc/ConcurrentIteration.git")!

		let repository = Repository.clone(from: cloneURL, to: tempDir)

		let firstRemote = try repository.get().allRemotes().get().first?.URL

		XCTAssertEqual(firstRemote, "https://github.com/allotropeinc/ConcurrentIteration.git")
    }
}


import Foundation
import XCTest
import Essentials
@testable import SwiftGit2


class RepositoryLocalTests: XCTestCase {
	func testCreateOpenRepo() {
		GitTest.tmpURL
			.flatMap { Repository.create(at: $0) }
			.assertFailure("create repo")
	}

	func testCreateAddFile() {
		GitTest.tmpURL
			.flatMap { Repository.create(at: $0) }
			.flatMap { $0.t_commit(msg: "initial commit") }
			.assertFailure("initial commit")
	}

}


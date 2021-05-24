
import Foundation
import XCTest
import Essentials
@testable import SwiftGit2

struct GitTest {
	static let localRoot = URL(fileURLWithPath: "/tmp/git_test", isDirectory: true)
}

struct PublicTestRepo {
	let urlSsh = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
	let urlHttps = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
	
	let localPath : URL
	
	init() {
		localPath = GitTest.localRoot.appendingPathComponent(urlSsh.lastPathComponent).deletingPathExtension()
		localPath.rm().assertFailure("rm")
	}
}

extension Result {
	@discardableResult
	func assertFailure(_ topic: String? = nil) -> Success? {
		self.onSuccess {
			if let topic = topic {
				print("\(topic) succeeded with: \($0)")
			}
		}.onFailure {
			if let topic = topic {
				print("\(topic) failed with: \($0.fullDescription)")
			}
			XCTAssert(false)
		}
		switch self {
		case .success(let s):
			return s
		default:
			return nil
		}
	}
}

extension String {
	func write(to file: URL) -> Result<(),Error> {
		do {
			try self.write(toFile: file.path, atomically: true, encoding: .utf8)
			return .success(())
		} catch {
			return .failure(error)
		}
	}
}

extension Repository {
	static func createTestRepo() -> Result<Repository,Error>  {
		URL.randomTempDirectory()
			.flatMap { Repository.create(at: $0) }
	}
	
//	func makeInitialCommit() {
//		self.createTest(file: fileName)
//		_ = self.add(path: fileName).wait()
//		self.waitStatusUpdate()
//
//		_ = self.commit(description: "initial commit", signature: testSignature).wait()
//		self.waitStatusUpdate()
//
//		self.createTest(file: fileName, idx: 1)
//		_ = self.add(path: fileName).wait()
//		self.forceRefresh()
//	}
}

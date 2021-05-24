
import Foundation
import XCTest
import Essentials
@testable import SwiftGit2

struct GitTest {
	static let localRoot = URL(fileURLWithPath: "/tmp/git_test", isDirectory: true)
	static let signature = Signature(name: "name", email: "email@domain.com")
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


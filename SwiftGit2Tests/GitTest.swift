
import Essentials
import Foundation
@testable import SwiftGit2
import XCTest

struct GitTest {
    static let prefix = "git_test"
    static var localRoot = URL(fileURLWithPath: "/tmp/\(prefix)", isDirectory: true)
    static var tmpURL: Result<URL, Error> { URL.tmp(.systemUnique, prefix: GitTest.prefix) }
    static let signature = Signature(name: "XCode Unit Test", email: "email@domain.com")
}

struct PublicTestRepo {
    let urlSsh = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
    let urlHttps = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!

    let localPath: URL
    let localPath2: URL

    init() {
        localPath = GitTest.localRoot.appendingPathComponent(urlSsh.lastPathComponent).deletingPathExtension()
        localPath2 = GitTest.localRoot.appendingPathComponent(localPath.lastPathComponent + "2")
        localPath.rm().assertFailure()
        localPath2.rm().assertFailure()
    }
}

extension Result {
    @discardableResult
    func assertBlock(_ topic: String? = nil, block: (Success) -> Bool) -> Success? {
        onSuccess {
            topic?.print(success: $0)
            XCTAssert(block($0))
        }.onFailure {
            topic?.print(failure: $0)
            XCTAssert(false)
        }
        return maybeSuccess
    }

    @discardableResult
    func assertFailure(_ topic: String? = nil) -> Success? {
        onSuccess {
            topic?.print(success: $0)
        }.onFailure {
            topic?.print(failure: $0)
            XCTAssert(false)
        }
        return maybeSuccess
    }

    @discardableResult
    func assertSuccess(_ topic: String? = nil) -> Success? {
        onSuccess {
            topic?.print(success: $0)
            XCTAssert(false)
        }.onFailure {
            topic?.print(failure: $0)
        }
        return maybeSuccess
    }

    @discardableResult
    func assertEqual(to: Success, _ topic: String? = nil) -> Success? where Success: Equatable {
        onSuccess {
            XCTAssert(to == $0)
            topic?.print(success: $0)
        }.onFailure {
            topic?.print(failure: $0)
            XCTAssert(false)
        }
        return maybeSuccess
    }

    @discardableResult
    func assertNotEqual(to: Success, _ topic: String? = nil) -> Success? where Success: Equatable {
        onSuccess {
            XCTAssert(to != $0)
            topic?.print(success: $0)
        }.onFailure {
            topic?.print(failure: $0)
            XCTAssert(false)
        }
        return maybeSuccess
    }

    var maybeSuccess: Success? {
        switch self {
        case let .success(s):
            return s
        default:
            return nil
        }
    }
}

extension String {
    func print<T>(success: T) {
        Swift.print("\(self) SUCCEEDED with: \(success)")
    }

    func print(failure: Error) {
        Swift.print("\(self) FAILED with: \(failure.localizedDescription)")
    }

    func write(to file: URL) -> Result<Void, Error> {
        do {
            try write(toFile: file.path, atomically: true, encoding: .utf8)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

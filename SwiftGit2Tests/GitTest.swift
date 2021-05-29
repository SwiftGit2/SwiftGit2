
import Foundation
import XCTest
import Essentials
@testable import SwiftGit2

struct GitTest {
    static let prefix = "git_test"
    static var localRoot = URL(fileURLWithPath: "/tmp/\(prefix)", isDirectory: true)
    static var tmpURL 	 : Result<URL, Error> { URL.tmp(.systemUnique, prefix: GitTest.prefix) }
    static let signature = Signature(name: "XCode Unit Test", email: "email@domain.com")
}

struct PublicTestRepo {
    let urlSsh = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
    let urlHttps = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
    
    let localPath : URL
    let localPath2 : URL
    
    init() {
        localPath  = GitTest.localRoot.appendingPathComponent(urlSsh.lastPathComponent).deletingPathExtension()
        localPath2 = GitTest.localRoot.appendingPathComponent(localPath.lastPathComponent + "2")
        localPath.rm().assertFailure()
        localPath2.rm().assertFailure()
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
                print("\(topic) failed with: \($0.localizedDescription)")
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
    
    @discardableResult
    func assertSuccess(_ topic: String? = nil) -> Success? {
        self.onSuccess {
            if let topic = topic {
                print("\(topic) succeeded with: \($0)")
            }
            XCTAssert(false)
        }.onFailure {
            if let topic = topic {
                print("\(topic) failed with: \($0.localizedDescription)")
            }
        }
        switch self {
        case .success(let s):
            return s
        default:
            return nil
        }
    }
    
    @discardableResult
    func assertEqual(to: Success, _ topic: String? = nil) -> Success? where Success: Equatable {
        self.onSuccess {
            XCTAssert(to == $0)
            if let topic = topic {
                print("\(topic) succeeded with: \($0)")
            }
        }.onFailure {
            if let topic = topic {
                print("\(topic) failed with: \($0.localizedDescription)")
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


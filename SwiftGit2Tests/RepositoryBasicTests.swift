//
//  SwiftGit2Tests.swift
//  SwiftGit2Tests
//
//  Created by loki on 16.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import XCTest
@testable import SwiftGit2
import Essentials

class RepositoryBasicTests: XCTestCase {
    let root = URL(fileURLWithPath: "/tmp/tao_test", isDirectory: true)
    
    override func setUpWithError() throws {
        root.mkdir()
            .onSuccess { print("\($0.absoluteString) created") }
            .onFailure { print("failure: \($0)")}
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testClone() {
        let remoteURL = URL(string: "git@github.com:libgit2/libgit2.git")!
        let localURL = root.appendingPathComponent("libgit2")
        Repository.clone(from: remoteURL, to: localURL)
            .assertFailure("clone")
    }
    
}

extension Result {
    func assertFailure(_ topic: String? = nil) {
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
    }
}

extension URL {
    func mkdir() -> Result<URL,Error> {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return .failure(error)
        }
        
        return .success(self)
    }
}


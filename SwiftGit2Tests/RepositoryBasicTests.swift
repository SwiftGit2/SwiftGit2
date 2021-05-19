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
    let remoteURL_test_public_ssh   = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
    let remoteURL_test_public_https = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
    let sshCredentials = Credentials.ssh(publicKey: "/Users/loki/.ssh/id_rsa.pub", privateKey: "/Users/loki/.ssh/id_rsa", passphrase: "")
    
    override func setUpWithError() throws {
        root.mkdir()
            .onSuccess { print("\($0.absoluteString) created") }
            .onFailure { print("failure: \($0)")}
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testHttpsAnonymouseClone() {
        let remoteURL = remoteURL_test_public_https
        let localURL = root.appendingPathComponent(remoteURL.lastPathComponent).deletingPathExtension()
        localURL.rm().assertFailure("rm")
        print("goint to clone into \(localURL)")

        Repository.clone(from: remoteURL, to: localURL, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone")
    }
    
    func testSSHDefaultClone() {
        let remoteURL = remoteURL_test_public_ssh
        let localURL = root.appendingPathComponent(remoteURL.lastPathComponent).deletingPathExtension()
        localURL.rm().assertFailure("rm")
        print("goint to clone into \(localURL)")

        Repository.clone(from: remoteURL, to: localURL, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
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

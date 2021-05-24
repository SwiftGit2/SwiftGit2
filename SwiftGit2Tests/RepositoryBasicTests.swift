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
        let info = PublicTestRepo()

        Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone")
    }
    
    func testSSHDefaultClone() {
        let info = PublicTestRepo()

        Repository.clone(from: info.urlSsh, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone")
    }
    
    func testCreateRepo() {
        let url = root.appendingPathComponent("NewRepo")
        let README_md = "README.md"
        url.rm().assertFailure("rm")
        
        guard let repo = Repository.create(at: url).assertFailure("Repository.create") else { fatalError() }
        
        let file = url.appendingPathComponent(README_md)
        "# test repository".write(to: file).assertFailure("write file")
        
        //if let status = repo.status().assertFailure("status") { XCTAssert(status.count == 1) } else { fatalError() }
        
        //repo.reset(paths: )
        repo.index().flatMap { $0.add(paths: [README_md]) }
            .assertFailure("index add \(README_md)")
        
        repo.commit(message: "initial commit", signature: Signature(name: "name", email: "email@domain.com"))
            .assertFailure("initial commit")
        
        
        
    }
    
}



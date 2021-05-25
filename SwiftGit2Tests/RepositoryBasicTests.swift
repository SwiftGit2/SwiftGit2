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

    override func setUpWithError()      throws { }
    override func tearDownWithError()   throws { }
    
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
        let url = GitTest.localRoot.appendingPathComponent("NewRepo")
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
    
    func testRemoteConnect() {
        let info = PublicTestRepo()
        
        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
                .assertFailure("clone") else { fatalError() }
        
        print(repo)
        
        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .fetch, auth: .credentials(.default)) } // shoud succeed
            .assertFailure("retmote.connect .fetch")
        
        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .push, auth: .credentials(.default)) } // should fail
            .assertSuccess("retmote.connect .push")
    }
    
}



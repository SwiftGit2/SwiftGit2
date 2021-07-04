//
//  SwiftGit2Tests.swift
//  SwiftGit2Tests
//
//  Created by loki on 16.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Essentials
@testable import SwiftGit2
import XCTest



class RepositoryRemoteTests: XCTestCase {
    override func setUpWithError() throws {}
    override func tearDownWithError() throws {}

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

    func testRemoteConnect() {
        let info = PublicTestRepo()

        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone") else { fatalError() }

        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .fetch, auth: .credentials(.default)) } // shoud succeed
            .assertFailure("retmote.connect .fetch")

        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .push, auth: .credentials(.default)) } // should fail
            .assertSuccess("retmote.connect .push")
        
        let creds = [GitTest.credentials_01, GitTest.credentials_bullshit] // last will be tried first
        
        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .push, possibleCreds: creds) }
            .assertFailure("retmote.connect .push") // should succeed
    }

    func testPush() {
        let info = PublicTestRepo()

        guard let repo = Repository.clone(from: info.urlSsh, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone") else { fatalError() }

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .assertFailure("t_commit")

        repo.detachHEAD().assertFailure("detachHEAD")

        repo.push()
            .assertSuccess("push")

        repo.detachedHeadFix().assertFailure("detachedHeadFix")

        repo.push()
            .assertFailure("push")
    }

    func testPushNoWriteAccess() {
        let info = PublicTestRepo()

        // use HTTPS anonymous access
        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone") else { fatalError() }

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .assertFailure("t_commit")

        // push should FAIL
        repo.push()
            .assertSuccess("push")
    }

    func testPushNoRemote() {
        let repo_ = GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .assertFailure("create repo")

        // for some reason it doesnt compile "let repo = repo"
        guard let repo = repo_ else { fatalError() }

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .assertFailure("t_commit")

        // push should FAIL
        repo.push()
            .assertSuccess("push")
    }
    
    func testUpstreamExists() {
        let info = PublicTestRepo()

        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .auto)))
            .assertFailure("clone") else { fatalError() }
        
        repo.upstreamExistsFor(.HEAD)
            .assertFailure("upstreamExistsFor")
        
        repo.createBranch(from: .head, name: "newBranch", checkout: true)
            .flatMap { repo.upstreamExistsFor(.branch($0)) }
            .assertEqual(to: false, "upstreamExistsFor newBranch")
        
        repo.t_commit(msg: "testcommit")
            .assertFailure()
        
        repo.pendingCommitsCount(.branchShortName("newBranch"))
            .assertEqual(to: .push(1), ".pendingCommitsCount(.branchShortName(newBranch))")
        
//        repo.pendingCommits(.branchShortName("newBranch"), .push)
//            .assertFailure("repo.pendingCommits(.branch($0), .push)")
        
    }
}

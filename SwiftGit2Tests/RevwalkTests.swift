//
//  RevwalkTests.swift
//  SwiftGit2Tests
//
//  Created by loki on 29.06.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Essentials
@testable import SwiftGit2
import XCTest

class RevwalkTests: XCTestCase {

    var repo1: Repository!
    var repo2: Repository!

    override func setUpWithError() throws {
        let info = PublicTestRepo()

        repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
            .assertFailure("clone 1")

        repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
            .assertFailure("clone 2")
    }
    
    func testRevwalk() {
        
        Revwalk.new(in: repo1)
            .flatMap { $0.push(range: "HEAD~20..HEAD") }
            .flatMap { $0.all() }
            .map { $0.count }
            .assertFailure("Revwalk.push(range")
        
        repo1.references(withPrefix: "refs/heads")
            .map { $0.map { $0.nameAsReference } }
            .assertFailure("references(withPrefix")
        
        repo1.t_commit(msg: "commit for Revvalk")
            .assertFailure("commit for Revvalk")
        
        Revwalk.new(in: repo1)
            .flatMap { $0.push(ref: "refs/heads/master") }
            .flatMap { $0.hide(ref: "refs/remotes/origin/master") }
            .flatMap { $0.all() }
            .map { $0.count }
            .assertFailure("Revwalk.push ..heads.., Revalk.hide ..remotes..")
        
        repo1.push()
            .assertFailure("")
        
        repo2.fetch(.HEAD)
            .assertFailure()
        
        repo2.mergeAnalysis(.HEAD)
            .assertEqual(to: [.fastForward, .normal])
        
        Revwalk.new(in: repo2)
            .flatMap { $0.push(ref: "refs/remotes/origin/master") }
            .flatMap { $0.hide(ref: "refs/heads/master") }
            .flatMap { $0.all() }
            .map { $0.count }
            .assertFailure("hide remotes, push heads")
    }
}

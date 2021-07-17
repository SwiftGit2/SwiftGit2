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
        
        repo1.t_commit(msg: "commit for Revvalk")
            .assertFailure()

        repo1.pendingCommits(.HEAD, .push)
            .map { $0.count }
            .assertEqual(to: 1, "repo1.pendingCommits(.HEAD, .push)")
                
        repo1.push(.HEAD)
            .assertFailure("push")
        
        repo2.fetch(.HEAD)
            .assertFailure()
        
        repo2.mergeAnalysis(.HEAD)
            .assertEqual(to: [.fastForward, .normal])
        
        repo2.pendingCommits(.HEAD, .fetch)
            .map { $0.count }
            .assertEqual(to: 1, "repo2.pendingCommits(.HEAD, .fetch)")
    }
}

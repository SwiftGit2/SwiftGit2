//
//  Repository+Pull.swift
//  SwiftGit2-OSX
//
//  Created by loki on 15.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Repository {
    func currentRemote() -> Result<Remote,Error> {
        return self.HEAD()
            .flatMap{ $0.asBranch() }
            .flatMap{ Duo($0, self).remote() }
    }
    
    func localCommit() -> Result<Commit, Error> {
        self.HEAD()
            .flatMap { $0.asBranch() }
            .flatMap { $0.commitOID }
            .flatMap { self.instanciate($0) }
    }
    
    func upstreamCommit() -> Result<Commit, Error> {
        self.HEAD()
            .flatMap { $0.asBranch() }
            .flatMap { $0.upstream() }
            .flatMap { $0.commitOID }
            .flatMap { self.instanciate($0) }
    }
    
    func pull(auth: Auth) {
        mergeAnalysis()
            //.flatMap(if: <#T##(MergeAnalysis) -> Bool#>, then: <#T##(MergeAnalysis) -> Result<NewSuccess, Error>#>, else: <#T##(MergeAnalysis) -> Result<NewSuccess, Error>#>)
    }
}

extension MergeAnalysis {
    func pull() {
        if self == .upToDate {
            return
        } else if contains(.fastForward) || contains(.unborn) {
            return
        } else if contains(.normal) {
            return
        }
        
        return
    }
}

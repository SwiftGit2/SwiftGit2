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
            .flatMap { $0.targetOID }
            .flatMap { self.instanciate($0) }
    }
    
    func upstreamCommit() -> Result<Commit, Error> {
        self.HEAD()
            .flatMap { $0.asBranch() }
            .flatMap { $0.upstream() }
            .flatMap { $0.targetOID }
            .flatMap { self.commit(oid: $0) }
    }
    
    func pull(auth: Auth) {
        mergeAnalysis()
            //.flatMap(if: <#T##(MergeAnalysis) -> Bool#>, then: <#T##(MergeAnalysis) -> Result<NewSuccess, Error>#>, else: <#T##(MergeAnalysis) -> Result<NewSuccess, Error>#>)
    }
    
    func pull(anal: MergeAnalysis, branch: Reference, commit: Commit) -> Result<(), Error>  {
        
        if anal == .upToDate {
            return .success(())
            
        } else if anal.contains(.fastForward) || anal.contains(.unborn) {
            
            return branch
                .set(target: commit.oid, message: "Fast-forward merge: REMOTE NAME -> \(branch.name)")
                .flatMap { $0.asBranch() }
                .flatMap { self.checkout(branch: $0) }
            
        } else if anal.contains(.normal) {
            
            return .failure(WTF("three way merge didn't implemented"))
        }
        
        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
        
    }
}

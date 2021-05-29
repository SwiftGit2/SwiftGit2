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
        //let branchUpstream = branch
        //	.flatMap { $0.upstream() }
        
        // 1. fetch remote
        // 2.
        currentRemote()
            .flatMap { $0.fetch(options: FetchOptions(auth: auth)) }
    }
}

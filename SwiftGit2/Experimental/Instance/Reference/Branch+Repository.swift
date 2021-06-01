//
//  Branch+Repository.swift
//  SwiftGit2-OSX
//
//  Created by loki on 30.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public extension Duo where T1 == Branch, T2 == Repository {
    func commit() -> Result<Commit, Error> {
        let (branch, repo) = value
        return branch.targetOID.flatMap { repo.instanciate($0) }
    }

    fileprivate func remoteName() -> Result<String, Error> {
        let (branch, repo) = value
        var buf = git_buf(ptr: nil, asize: 0, size: 0)

        return git_try("git_branch_upstream_remote") {
            return branch.nameAsReference.withCString { branchName in
                git_branch_upstream_remote(&buf, repo.pointer, branchName)
            }
        }.flatMap { Buffer(buf: buf).asString() }
    }

    /// Gets REMOTE item from local branch. Doesn't works with remote branch
    func remote() -> Result<Remote, Error> {
        let (_, repo) = value

        return remoteName()
            .flatMap { remoteName in
                repo.remoteRepo(named: remoteName)
            }
    }
}

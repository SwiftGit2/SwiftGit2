//
//  Repository+Fetch.swift
//  SwiftGit2-OSX
//
//  Created by loki on 28.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation
import Essentials

public enum GitTarget {
    case HEAD
    case branch(Branch)
}

public extension Repository {
    func fetch(_ target: GitTarget, options: FetchOptions = FetchOptions()) -> Result<Branch, Error> {
        switch target {
        case .HEAD:
            return HEAD()
                .flatMap { $0.asBranch() }
                .flatMap { self.fetch(.branch($0)) } // very fancy recursion
        case let .branch(branch):
            return Duo(branch, self).remote()
                .flatMap { $0.fetch(options: options) }
                .map { branch }
        }
    }
}

public extension Remote {
    func fetch(options: FetchOptions) -> Result<Void, Error> {
        return git_try("git_remote_fetch") {
            options.with_git_fetch_options {
                git_remote_fetch(pointer, nil, &$0, nil)
            }
        }
    }
}

internal extension Repository {
    func upstreamExistsFor(_ target: GitTarget) -> R<Bool> {
        switch target {
        case .HEAD:
            return HEAD()
                .flatMap { $0.asBranch() }
                .flatMap { self.upstreamExistsFor(.branch($0)) } // very fancy recursion
        case let .branch(branch):
            return branch
                .upstream()
                .map { _ in true }
                .flatMapError {
                    let error = $0 as NSError
                    
                    if let reason = error.localizedFailureReason, reason.starts(with: "git_branch_upstream") {
                        if error.code == -3 {
                            return .success(false)
                        }
                    }
                    return .failure(error)
                }
        }
    }
}

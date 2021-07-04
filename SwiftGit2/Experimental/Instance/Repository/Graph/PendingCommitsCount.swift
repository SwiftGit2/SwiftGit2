//
//  PendingCommitsCount.swift
//  SwiftGit2-OSX
//
//  Created by loki on 05.07.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation
import Essentials

public enum PendingCommitsCount {
    case pushpull(Int,Int)
    case push(Int)          // no upastream
    case undefined
}

public extension Repository {
    func pendingCommitsCount(_ target: BranchTarget) -> R<PendingCommitsCount> {
        if headIsDetached {
            return .success(.undefined)
        }
        
        return upstreamExistsFor(target)
            .if(\.self, then: { _ in
                _pendingCommitsCount(target)
                    .map { PendingCommitsCount.pushpull($0, $1) }
            }, else: { _ in
                self.branches(.remote).flatMap { _pendingCommits(remoteBranches: $0, target: target) }
            })
    }
    
    func _pendingCommits(remoteBranches branches : [Branch], target: BranchTarget) -> R<PendingCommitsCount> {
        let names = branches.compactMap { $0.nameAsBranch }
        if names.isEmpty {
            return .success(.undefined)
        }
        
        let local = target.branch(in: self) | { $0.targetOID }
        let upstream = branches.findMainBranch().flatMap { $0.targetOID }
        //
        return combine(local,upstream)
            .flatMap { graphAheadBehind(local: $0, upstream: $1) }
            .map { ahead, behind in .push(ahead) }
    }

    func _pendingCommitsCount(_ target: BranchTarget) -> R<(Int,Int)> {
        let push = pendingCommits(target, .push)    | { $0.count }
        let fetch = pendingCommits(target, .fetch)  | { $0.count }
        
        return combine(push, fetch)
    }
}

internal extension Array where Element == Branch {
    func findMainBranch() -> R<Branch> {
        for item in self {
            if item.nameAsBranch == "main" {
                return .success(item)
            }
            
            if item.nameAsBranch == "master" {
                return .success(item)
            }
        }
        
        if let item = self.first {
            return .success(item)
        }
        return .failure(WTF("findMainBranch(): array is empty"))
    }
}


extension PendingCommitsCount: Equatable {
    public static func == (lhs: PendingCommitsCount, rhs: PendingCommitsCount) -> Bool {
        switch (lhs, rhs) {
        case (.undefined, .undefined): return true
        case let (.push(lp), .push(rp)): return lp == rp
        case let (.pushpull(lpush,lpull), .pushpull(rpush, rpull)): return lpush == rpush && lpull == rpull
        default:
            return false
        }
    }
}

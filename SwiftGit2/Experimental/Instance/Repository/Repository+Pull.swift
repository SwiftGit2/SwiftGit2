//
//  Repository+Pull.swift
//  SwiftGit2-OSX
//
//  Created by loki on 15.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import Foundation

public enum PullResult {
    case upToDate
    case fastForward
    case threeWaySuccess
    case threeWayConflict(Index)
}

public extension Repository {
    func pull(_ target: FetchTarget, options: FetchOptions = FetchOptions(auth: .auto), signature: Signature) -> Result<PullResult, Error> {
        return combine(fetch(target, options: options), mergeAnalysis(target))
            .flatMap { branch, anal in self.mergeFromUpstream(anal: anal, ourLocal: branch, signature: signature) }
    }

    private func mergeFromUpstream(anal: MergeAnalysis, ourLocal: Branch, signature: Signature) -> Result<PullResult, Error> {
        guard !anal.contains(.upToDate) else { return .success(.upToDate) }

        let theirReference = ourLocal
            .upstream()

        if anal.contains(.fastForward) || anal.contains(.unborn) {
            /////////////////////////////////////
            // FAST-FORWARD MERGE
            /////////////////////////////////////

            let targetOID = theirReference
                .flatMap { $0.targetOID }

            let message = theirReference.map { their in "Fast Forward MERGE \(their.nameAsReference) -> \(ourLocal.nameAsReference)" }

            return combine(targetOID, message)
                .flatMap { oid, message in ourLocal.set(target: oid, message: message) }
                .flatMap { $0.asBranch() }
                .flatMap { self.checkout(branch: $0, strategy: .Force) }
                .map { _ in .fastForward }

        } else if anal.contains(.normal) {
            /////////////////////////////////
            // THREE-WAY MERGE
            /////////////////////////////////

            let ourOID = ourLocal.targetOID
            let theirOID = ourLocal.upstream().flatMap { $0.targetOID }
            let baseOID = combine(ourOID, theirOID).flatMap { self.mergeBase(one: $0, two: $1) }

            let message = combine(theirReference, baseOID)
                .map { their, base in "Three Way MERGE \(their.nameAsReference) -> \(ourLocal.nameAsReference) with BASE \(base)" }

            let ourCommit = ourOID.flatMap { self.commit(oid: $0) }
            let theirCommit = theirOID.flatMap { self.commit(oid: $0) }

            let parents = combine(ourCommit, theirCommit)
                .map { [$0, $1] }

            let branchName = ourLocal.nameAsReference

            return [ourOID, theirOID, baseOID]
                .flatMap { $0.tree(self) }
                .flatMap { self.merge(our: $0[0], their: $0[1], ancestor: $0[2]) } // -> Index
                .if(\.hasConflicts,
                    then: { idx in
                        self.checkout(index: idx, strategy: .UseTheirs)
                            .flatMap { _ in .success(.threeWayConflict(idx)) }
                    },

                    else: { index in
                        combine(message, parents)
                            .flatMap { index.commit(into: self, signature: signature, message: $0, parents: $1) }
                            .flatMap { _ in self.checkout(branch: branchName, strategy: .Force) }
                            .map { _ in .threeWaySuccess }
                    })
        }

        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
    }
}

private extension Result where Success == OID, Failure == Error {
    func tree(_ repo: Repository) -> Result<Tree, Error> {
        flatMap { repo.commit(oid: $0) }
            .flatMap { $0.tree() }
    }
}

internal extension Index {
    func commit(into repo: Repository, signature: Signature, message: String, parents: [Commit]) -> Result<Void, Error> {
        writeTree(to: repo)
            .flatMap { tree in repo.commitCreate(signature: signature, message: message, tree: tree, parents: parents) }
            .map { _ in () }
    }
}

extension PullResult: Equatable {
    var hasConflict: Bool {
        if case .threeWayConflict = self {
            return true
        } else {
            return false
        }
    }

    public static func == (lhs: PullResult, rhs: PullResult) -> Bool {
        switch (lhs, rhs) {
        case (.upToDate, .upToDate): return true
        case (.fastForward, .fastForward): return true
        case (.threeWaySuccess, .threeWaySuccess): return true
        default:
            return false
        }
    }
}

// public static func == (lhs: DetachedHeadFix, rhs: DetachedHeadFix) -> Bool {
//    switch (lhs, rhs) {
//    case (.fixed, .fixed): return true
//    case (.notNecessary, .notNecessary): return true
//    case let (.ambiguous(a_l), .ambiguous(a_r)):
//        return a_l == a_r
//    default: return false
//    }
// }

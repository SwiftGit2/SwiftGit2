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
    
    func pull(options: FetchOptions = FetchOptions(auth: .auto), signature: Signature) -> Result<(), Error> {
        return combine(self.fetch(.HEAD, options: options), mergeAnalysis(.HEAD))
            .flatMap { branch, anal in self.mergeFromUpstream(anal: anal, ourLocal: branch, signature: signature)}
    }
    
    private func mergeFromUpstream(anal: MergeAnalysis, ourLocal: Branch, signature: Signature) -> Result<(), Error>  {
        guard !anal.contains(.upToDate) else { return .success(()) }
        
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
                .flatMap { self.checkout(branch: $0) }
            
        } else if anal.contains(.normal) {
            /////////////////////////////////
            // THREE-WAY MERGE
            /////////////////////////////////
            
            let ourOID   = ourLocal.targetOID
            let theirOID = ourLocal.upstream().flatMap { $0.targetOID }
            let baseOID  = combine(ourOID, theirOID).flatMap { self.mergeBase(one: $0, two: $1) }
            
            let message = combine(theirReference, baseOID)
                .map { their, base in "Three Way MERGE \(their.nameAsReference) -> \(ourLocal.nameAsReference) with BASE \(base)" }
            
            let ourCommit = ourOID.flatMap { self.commit(oid: $0) }
            let theirCommit = theirOID.flatMap { self.commit(oid: $0) }
            
            let parents = combine(ourCommit, theirCommit)
                .map { [$0,$1] }
            
            return combine(ourOID.tree(self), theirOID.tree(self), baseOID.tree(self))
                .flatMap { self.merge(our: $0, their: $1, ancestor: $2) }
                .flatMap(if:   { index in index.hasConflicts },
                         then: { _ in .failure(WTF("three way merge didn't implemented")) },
                         else: { index in
                            combine(message, parents)
                                .flatMap { index.commit(into: self, signature: signature, message: $0, parents: $1)}
                         }
                )
        }
        
        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
    }
}

private extension Result where Success == OID, Failure == Error {
    func tree(_ repo: Repository) -> Result<Tree, Error> {
        self.flatMap { repo.commit(oid: $0) }
            .flatMap { $0.tree() }
    }
}

internal extension Index {
    func commit(into repo: Repository, signature: Signature, message: String, parents: [Commit]) -> Result<Void, Error> {
        self.writeTree(to: repo)
            .flatMap { tree in repo.commitCreate(signature: signature, message: message, tree: tree, parents: parents) }
            .map { _ in () }
    }
}

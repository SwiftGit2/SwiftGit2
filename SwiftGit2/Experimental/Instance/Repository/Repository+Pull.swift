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
    
    func pull(options: FetchOptions = FetchOptions(auth: .auto)) -> Result<(), Error> {
        return combine(self.fetch(.HEAD, options: options), mergeAnalysis(.HEAD))
            .flatMap { branch, anal in self.pull(anal: anal, ourLocal: branch)}
    }
    
    private func pull(anal: MergeAnalysis, ourLocal: Branch) -> Result<(), Error>  {
        
        if anal == .upToDate {
            
            return .success(())
        } else if anal.contains(.fastForward) || anal.contains(.unborn) {
            /////////////////////////////////////
            // FAST-FORWARD MERGE
            /////////////////////////////////////
            
            let theirReference = ourLocal
                .upstream()
            
            let targetOID = theirReference
                .flatMap { $0.targetOID }
            
            return combine(theirReference, targetOID)
                .flatMap { their, oid in ourLocal.set(target: oid, message: "Fast Forward MERGE \(their.nameAsReference) -> \(ourLocal.nameAsReference)") }
                .flatMap { $0.asBranch() }
                .flatMap { self.checkout(branch: $0) }
            
        } else if anal.contains(.normal) {
            /////////////////////////////////
            // THREE-WAY MERGE
            /////////////////////////////////
            
            let ourOID   = ourLocal.targetOID
            let theirOID = ourLocal.upstream().flatMap { $0.targetOID }
            
            let baseTree    = combine(ourOID, theirOID).flatMap { self.mergeBase(one: $0, two: $1) }.tree(self)
            let ourTree     = ourOID.tree(self)
            let theirTree   = theirOID.tree(self)
            
            return combine(ourTree, theirTree, baseTree)
                .flatMap { self.merge(our: $0, their: $1, ancestor: $2) }
                .flatMap(if: { $0.hasConflicts },
                         then: { _ in .failure(WTF("three way merge didn't implemented")) },
                         else: { _ in .failure(WTF("three way merge didn't implemented")) } )
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
    func commit(into repo: Repository, signature: Signature, message: String, parents: [Commit]) -> Result<Commit, Error> {
        self.writeTree(to: repo)
            .flatMap { tree in repo.commitCreate(signature: signature, message: message, tree: tree, parents: parents) }
    }
}

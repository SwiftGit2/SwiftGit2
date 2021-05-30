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
    
    func pull(auth: Auth) -> Result<(), Error> {
        let branch = self.HEAD()
            .flatMap { $0.asBranch() }
        
        return combine(mergeAnalysis(), branch)
            .flatMap { anal, branch in self.pull(anal: anal, ourLocal: branch)}
    }
    
    func pull(anal: MergeAnalysis, ourLocal: Branch) -> Result<(), Error>  {
        
        if anal == .upToDate {
            
            return .success(())
        } else if anal.contains(.fastForward) || anal.contains(.unborn) {
            
            let theirReference = ourLocal
                .upstream()
            
            let targetOID = theirReference
                .flatMap { $0.targetOID }
            
            return combine(theirReference, targetOID)
                .flatMap { their, oid in ourLocal.set(target: oid, message: "Fast Forward MERGE \(their.nameAsReference) -> \(ourLocal.nameAsReference)") }
                .flatMap { $0.asBranch() }
                .flatMap { self.checkout(branch: $0) }
            
        } else if anal.contains(.normal) {
            
            let theirTree = ourLocal.upstream()
                .flatMap { $0.targetOID }
                .flatMap { self.commit(oid: $0) }
                .flatMap { $0.tree() }
            
            
            return .failure(WTF("three way merge didn't implemented"))
        }
        
        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
        
    }
}

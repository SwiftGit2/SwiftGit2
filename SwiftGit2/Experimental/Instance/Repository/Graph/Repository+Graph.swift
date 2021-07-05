//
//  Repository+Graph.swift
//  SwiftGit2-OSX
//
//  Created by loki on 04.07.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Repository {
    /*
     branch is X commits behind means that there are X new (unmerged) commits on the branch
     which is being tracked by your current branch.
     
     branch is X commits ahead analogously means that your branch has X new commits,
     which haven't been merged into the tracked branch yet.
     */
    func graphAheadBehind(local: OID, upstream: OID) -> R<(Int,Int)> {
        var ahead : Int = 0 //number of unique from commits in `upstream`
        var behind : Int = 0 //number of unique from commits in `local`
        var localOID = local.oid
        var upstreamOID = upstream.oid
        
        return git_try("git_graph_ahead_behind") {
            let tmp = git_graph_ahead_behind(&ahead,&behind,self.pointer,&localOID,&upstreamOID)
            let repoURL = (try? self.directoryURL.get())?.path ?? "error"
            print("\(repoURL): ahead \(ahead), behind \(behind)")
            return tmp
        } | { (ahead, behind) }
    }
    
    func graphDescendantOf(commitOID: OID, ancestorOID: OID) -> Bool {
        var commitOID = commitOID.oid
        var ancestorOID = ancestorOID.oid
        
        return 1 == git_graph_descendant_of(self.pointer, &commitOID, &ancestorOID)
    }
}

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
    func _graphAheadBehind(local: OID, upstream: OID) -> Int {
        var ahead : Int = 0 //number of unique from commits in `upstream`
        var behind : Int = 0 //number of unique from commits in `local`
        var localOID = local.oid
        var upstreamOID = upstream.oid
        
        let r =  Int(git_graph_ahead_behind(&ahead,&behind,self.pointer,&localOID,&upstreamOID))
        
        return r
    }
}

//
//  Repository+Blob.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 25.07.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Repository {
    
    func blobCreateFromDisk(path: String) -> R<OID> {
        var oid = git_oid()
        
        return _result({ OID(oid) }, pointOfFailure: "git_blob_create_from_disk") {
            path.withCString{ path1 in
                Clibgit2.git_blob_create_from_disk(&oid, self.pointer, path1)
            }
        }
    }
    
    func blobCreateFromWorkdir(relPath: String) -> R<OID> {
        var oid = git_oid()
        
        return _result({ OID(oid) }, pointOfFailure: "git_blob_create_from_workdir") {
            relPath.withCString{ path1 in
                Clibgit2.git_blob_create_from_workdir(&oid, self.pointer, path1)
            }
        }
    }
    
    func blobCreateFromWorkdirAsBlob(relPath: String) -> R<Blob> {
        let repo = self
        
        return blobCreateFromWorkdir(relPath: relPath).flatMap{ repo.blob(oid: $0) }
    }
}

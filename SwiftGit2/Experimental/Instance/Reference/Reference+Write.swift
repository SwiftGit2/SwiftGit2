//
//  Reference+Write.swift
//  SwiftGit2-OSX
//
//  Created by loki on 09.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public enum ReferenceName {
    case full(String)
    case branch(String)
    case remote(String)
}

public extension Repository {
    func rename(reference: String, to newName: ReferenceName) -> Result<Reference, Error> {
        return self.reference(name: reference)
            .flatMap { $0.rename( newName) }
    }
}

public extension Reference {
    func rename( _ name: ReferenceName, force: Bool = false) -> Result<Reference,Error> {
        switch name {
        case let .full(name):
            return rename(name, force: force)
            
        case let .branch(name):
            if isBranch {
                return rename("refs/heads/\(name)", force: force)
            } else {
                return .failure(WTF("can't rename reference in 'refs/heads' namespace: \(self.name)"))
            }
            
        case let .remote(name):
            let sections = self.name.split(separator: "/")
            
            if isRemote && sections.count >= 3 {
                let origin = sections[2]
                return rename("refs/remotes/\(origin)/\(name)", force: force)
            } else {
                return .failure(WTF("can't rename reference in 'refs/remotes' namespace: \(self.name)"))
            }
        }
    }
    
    private func rename(_ newName: String, force: Bool = false) -> Result<Reference,Error> {
        var pointer: OpaquePointer? = nil
        
        return commitOID.flatMap { oid in
            let logMsg = "Reference.rename: [OID: \(oid)] \(self.name) -> \(newName)"
            
            return git_try("git_reference_rename") {
                git_reference_rename(&pointer, self.pointer, newName, force ? 1 : 0, logMsg)
            }
        }.map { Reference(pointer!) }
    }
}

public extension Branch {
    func delete() -> Result<(), Error> {
        return git_try("git_branch_delete") {
            git_branch_delete(self.pointer)
        }
    }
}

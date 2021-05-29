//
//  Reference+Write.swift
//  SwiftGit2-OSX
//
//  Created by loki on 09.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

enum RefWriterError: Error {
    case NameHaveNoCorrectPrefix
    case BranchWasntFound
    case Unknown
}

extension Reference {
    public func rename(_ newName: String, force: Bool = false) -> Result<Reference,Error> {
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
    ///Need to use FULL name. ShortName will fail.
    func rename(to newName: String ) -> Result<Reference, Error> {
        if( !newName.starts(with: "refs/heads/") && !newName.starts(with: "refs/remotes/")) {
            return .failure(RefWriterError.NameHaveNoCorrectPrefix as Error)
        }
        
        return (self as! Reference).rename(newName)
    }
    
    func renameLocalUsingUnifiedName(to newName: String) -> Result<Reference, Error> {
        if self.isLocalBranch {
            return (self as! Reference).rename("refs/heads/\(newName)")
        }
        return .failure(RefWriterError.BranchWasntFound as Error)
    }
    
    func renameRemoteUsingUnifiedName(to newName: String ) -> Result<Reference, Error> {
        if self.isRemoteBranch {
            let sections = self.name.split(separator: "/")
            if sections.count < 3 {
                return .failure(RefWriterError.Unknown as Error)
            }
            let origin = sections[2]
            
            return  (self as! Reference).rename("refs/remotes/\(origin)/\(newName)")
        }
        
        return .failure(RefWriterError.BranchWasntFound as Error)
    }
    
    
    func delete() -> Result<(), Error> {
        return git_try("git_branch_delete") {
            git_branch_delete(self.pointer)
        }
    }
}

public extension Repository {
    func rename(reference: String, to newName: String) -> Result<Reference, Error> {
        return self.reference(name: reference)
            .flatMap { $0.rename( newName) }
    }
}

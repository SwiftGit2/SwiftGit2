//
//  ReferenceInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Reference : Branch { // Branch: InstanceProtocol
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_reference_free(pointer)
    }
}

public extension Reference  {
    var name        : String { String(validatingUTF8: git_reference_name(pointer)) ?? "" }
    //var oid         : OID  { OID(git_reference_target(pointer).pointee) }
    
    var isTag       : Bool { git_reference_is_tag(pointer) != 0 }
    var isDirect    : Bool { git_reference_type(pointer) == GIT_REFERENCE_DIRECT }
    var isSymbolic  : Bool { git_reference_type(pointer) == GIT_REFERENCE_SYMBOLIC }
    
    func asBranch() -> Result<Branch, Error> {
        if isBranch || isRemote {
            return .success(self as Branch)
        }
        return .failure(WTF("asBranch() failed for \(name)"))
    }
    
    @available(*, deprecated, message: "use asBranch() instead")
    var asBranch_ : Branch? {
        if isBranch || isRemote {
            return self as Branch
        }
        return nil
    }

    var targetOID : Result<OID, Error> {
        if isSymbolic {
            var resolved: OpaquePointer? = nil
            defer {
                git_reference_free(resolved)
            }
            
            return git_try("git_reference_resolve")
                { git_reference_resolve(&resolved, self.pointer) }
                .map { OID(git_reference_target(resolved).pointee) }
        } else {
            return .success( OID(git_reference_target(pointer).pointee) )
        }

    }
}

public extension Repository {	
    func references(withPrefix prefix: String) -> Result<[Reference], Error> {
        var strarray = git_strarray()
        defer {
            git_strarray_free(&strarray) // free results of the git_reference_list call
        }
        
        return git_try("git_reference_list") {
            git_reference_list(&strarray, self.pointer)
        }
        .map { strarray.filter { $0.hasPrefix(prefix) } }
        .flatMap { $0.flatMap { self.reference(name: $0) } }
    }
    
    func reference(name: String) -> Result<Reference, Error> {
        var pointer: OpaquePointer? = nil
        
        return _result({ Reference(pointer!) }, pointOfFailure: "git_reference_lookup") {
            git_reference_lookup(&pointer, self.pointer, name)
        }
    }
}

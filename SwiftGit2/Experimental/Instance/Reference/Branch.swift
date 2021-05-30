//
//  BranchInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Branch
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public enum BranchLocation {
    case local
    case remote
}

public protocol Branch: InstanceProtocol {
    var nameAsBranch        : String?   { get }
    var nameAsReference     : String    { get }
    var isBranch            : Bool      { get }
    var isRemote            : Bool      { get }
    
    var targetOID           : Result<OID, Error> { get }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Reference
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extension Branch {
    public var nameAsBranch 	: String? 	{ ( try? branchName.get() ) }
}

public extension Branch {
    /// can be called only for local branch;
    ///
    /// newName looks like "BrowserGridItemView" BUT NOT LIKE "refs/heads/BrowserGridItemView"
    func setUpstreamName(newName: String) -> Result<Branch, Error> {
        let cleanedName = newName.replace(of: "refs/heads/", to: "")
        
        return _result({ self }, pointOfFailure: "git_branch_set_upstream" ) {
            cleanedName.withCString { newBrName in
                git_branch_set_upstream(self.pointer, newBrName);
            }
        }
    }
    
    /// can be called only for local branch;
    func upstreamName(clean: Bool = false) -> Result<String, Error> {
        if clean {
            return upstream().map{ $0.nameAsReference.replace(of: "refs/remotes/", to: "") }
        }
        
        return upstream().map{ $0.nameAsReference }
    }
    
    /// Can be used only on local branch
    func upstream() -> Result<Branch, Error> {
        var resolved: OpaquePointer? = nil
        
        return git_try("git_branch_upstream") { git_branch_upstream(&resolved, self.pointer) }
            .flatMap { Reference(resolved!).asBranch() }
    }
    
    /// can be called only for local branch;
    ///
    /// newNameWithPath MUST BE WITH "refs/heads/"
    /// Will reset assigned upstream Name
    func setLocalName(newNameWithPath: String) -> Result<Branch, Error> {
        guard   newNameWithPath.contains("refs/heads/")
        else { return .failure(BranchError.NameIsNotLocal as Error) }
        
        return (self as! Reference).rename(.full(newNameWithPath)).flatMap { $0.asBranch() }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Repository
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// High Level code


// Low Level code
public extension Repository {
    func branches( _ location: BranchLocation) -> Result<[Branch], Error> {
        switch location {
        case .local:
            return references(withPrefix: "refs/heads/")
                .flatMap { $0.flatMap { $0.asBranch() } }
            
        case .remote:
            return references(withPrefix: "refs/remotes/")
                .flatMap { $0.flatMap { $0.asBranch() } }
        }
    }
    
    /// Get upstream name by branchName
    func upstreamName(branchName: String) -> Result<String, Error> {
        var buf = git_buf(ptr: nil, asize: 0, size: 0)
        
        return  _result({Buffer(buf: buf)}, pointOfFailure: "" ) {
            branchName.withCString { refname in
                git_branch_upstream_name(&buf, self.pointer, refname)
            }
        }
        .flatMap { $0.asString() }
    }
}

private extension Branch {
    private var branchName : Result<String, Error> {
        var pointer: UnsafePointer<Int8>? = nil // Pointer to the abbreviated reference name. Owned by ref, do not free.
        
        return git_try("git_branch_name") {
            git_branch_name(&pointer, self.pointer)
        }
        .flatMap { String.validatingUTF8(cString: pointer!) }
    }
}

fileprivate extension String {
    func replace(of: String, to: String) -> String {
        return self.replacingOccurrences(of: of, with: to, options: .regularExpression, range: nil)
    }
}

////////////////////////////////////////////////////////////////////
///ERRORS
////////////////////////////////////////////////////////////////////

enum BranchError: Error {
    //case BranchNameIncorrectFormat
    case NameIsNotLocal
    //case NameMustNotContainsRefsRemotes
}

extension BranchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        //	case .BranchNameIncorrectFormat:
        //	  return "Name must include 'refs' or 'home' block"
        case .NameIsNotLocal:
            return "Name must be Local. It must have include 'refs/heads/'"
        //	case .NameMustNotContainsRefsRemotes:
        //	  return "Name must be Remote. But it must not contain 'refs/remotes/'"
        }
    }
}

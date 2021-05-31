//
//  IndexInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public final class Index : InstanceProtocol {
    public var pointer: OpaquePointer
    
    required public init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_index_free(pointer)
    }
}

public extension Repository {
    func index() -> Result<Index, Error> {
        var pointer: OpaquePointer? = nil
        
        return _result( { Index(pointer!) }, pointOfFailure: "git_repository_index") {
            git_repository_index(&pointer, self.pointer)
        }
    }
}

public extension Index {
    var entrycount : Int { git_index_entrycount(pointer) }
    
    var hasConflicts : Bool { git_index_has_conflicts(pointer) == 1}
    
    func entries() -> Result<[Index.Entry], Error> {
        var entries = [Index.Entry]()
        for i in 0..<entrycount {
            if let entry = git_index_get_byindex(pointer, i) {
                entries.append(Index.Entry(entry: entry.pointee))
            }
        }
        return .success(entries)
    }
    
    func add(paths: [String]) -> Result<(), Error> {
        return paths.with_git_strarray { strarray in
            return _result((), pointOfFailure: "git_index_add_all") {
                git_index_add_all(pointer, &strarray, 0, nil, nil)
            }
            .flatMap { self.write() }
        }
    }
    
    func remove(path: String) -> Result<(), Error> {
        return [path].with_git_strarray { strarray in
            return _result((), pointOfFailure: "git_index_add_all") {
                git_index_remove_all(pointer, &strarray, nil, nil)
            }
            .flatMap { self.write() }
        }
    }
    
    func clear() -> Result<(), Error> {
        _result((), pointOfFailure: "git_index_clear") { git_index_clear(pointer) }
    }
    
    private func write() -> Result<(),Error> {
        _result((), pointOfFailure: "git_index_write") { git_index_write(pointer) }
    }
    
    func getTreeOID() -> Result<git_oid, Error> {
        var treeOID = git_oid() // out
        
        return _result({ treeOID }, pointOfFailure: "git_index_write_tree") {
            git_index_write_tree(&treeOID, self.pointer)
        }
    }
}

public extension Duo where T1 == Index, T2 == Repository {
    func commit(message: String, signature: Signature) -> Result<Commit, Error> {
        let (index,repo) = self.value
        
        return index.getTreeOID()
            .flatMap { treeOID in
                
                return repo.headCommit()
                    // If commit exist
                    .flatMap{ commit in
                        repo.commit(tree: OID(treeOID), parents: [commit], message: message, signature: signature)
                    }
                    // if there are no parents: initial commit
                    .flatMapError { _ in
                        repo.commit(tree: OID(treeOID), parents: [], message: message, signature: signature)
                    }
            }
    }
    
    /// return OID of written tree
    func writeIndex() -> Result<OID, Error>  {
        let (index, repo) = self.value
        
        var oid = git_oid() // out
        
        return _result( { OID(oid) } , pointOfFailure: "git_index_write_tree_to") {
            git_index_write_tree_to(&oid, index.pointer, repo.pointer);
        }
    }
}

fileprivate extension Repository {
    /// If no parents write "[]"
    /// Perform a commit with arbitrary numbers of parent commits.
    func commit( tree treeOID: OID, parents: [Commit], message: String, signature: Signature ) -> Result<Commit, Error> {
        // create commit signature
        return signature.makeUnsafeSignature().flatMap { signature in
            defer { git_signature_free(signature) }
            
            return gitTreeLookup(tree: treeOID).flatMap { tree in
                // Clean up excess whitespace
                // + make sure there is a trailing newline in the message
                var msgBuf = git_buf()
                defer { git_buf_free(&msgBuf) }
                git_message_prettify(&msgBuf, message, 0, /* ascii for # */ 35)
                
                // libgit2 expects a C-like array of parent git_commit pointer
                let parentGitCommits: [OpaquePointer?] = parents.map { $0.pointer }
                let parentsContiguous = ContiguousArray(parentGitCommits)
                
                return parentsContiguous.withUnsafeBufferPointer { unsafeBuffer in
                    var commitOID = git_oid()
                    let parentsPtr = UnsafeMutablePointer(mutating: unsafeBuffer.baseAddress)
                    
                    return _result( { OID(commitOID) } , pointOfFailure: "git_commit_create") {
                        git_commit_create( &commitOID, self.pointer, "HEAD", signature, signature,
                                           "UTF-8", msgBuf.ptr, tree.pointer, parents.count, parentsPtr )
                    }
                    .flatMap{ currOID in
                        self.instanciate(currOID)
                    }
                }
            }
        }
    }
    
    private func gitTreeLookup(tree treeOID: OID) -> Result<Tree, Error> {
        var tree: OpaquePointer? = nil
        var treeOIDCopy = treeOID.oid
        
        return _result( { Tree(tree!) } , pointOfFailure: "git_tree_lookup") {
            git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
        }
    }
}

//internal extension Repository {
//    func commitCreate() {
//        var outOID = git_oid()
//        git_commit_create(&outOID, self.pointer, "HEAD", <#T##author: UnsafePointer<git_signature>!##UnsafePointer<git_signature>!#>, <#T##committer: UnsafePointer<git_signature>!##UnsafePointer<git_signature>!#>, <#T##message_encoding: UnsafePointer<CChar>!##UnsafePointer<CChar>!#>, <#T##message: UnsafePointer<CChar>!##UnsafePointer<CChar>!#>, <#T##tree: OpaquePointer!##OpaquePointer!#>, <#T##parent_count: Int##Int#>, <#T##parents: UnsafeMutablePointer<OpaquePointer?>!##UnsafeMutablePointer<OpaquePointer?>!#>)
//    }
//}

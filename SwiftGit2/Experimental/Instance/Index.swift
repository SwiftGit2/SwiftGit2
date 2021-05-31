//
//  IndexInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

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
        return gitTreeLookup(tree: treeOID)
            .flatMap { self.commitCreate(signature: signature, message: message, tree: $0, parents: parents) }
    }
    
    private func gitTreeLookup(tree treeOID: OID) -> Result<Tree, Error> {
        var tree: OpaquePointer? = nil
        var treeOIDCopy = treeOID.oid
        
        return _result( { Tree(tree!) } , pointOfFailure: "git_tree_lookup") {
            git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
        }
    }
}

internal extension Repository {
    func commitCreate(signature: Signature, message: String, tree: Tree, parents: [Commit]) -> Result<Commit,Error> {
        var outOID = git_oid()
        let parentsPointers: [OpaquePointer?] = parents.map { $0.pointer }
        
        return combine(signature.make(), Buffer.prettify(message: message))
            .flatMap { signature, buffer in
                git_try("git_commit_create") {
                    parentsPointers.withUnsafeBufferPointer { unsafeBuffer in
                        let parentsPtr = UnsafeMutablePointer(mutating: unsafeBuffer.baseAddress)
                        return git_commit_create(&outOID, self.pointer, "HEAD", signature.pointer , signature.pointer,
                                                 "UTF-8", buffer.buf.ptr, tree.pointer, parents.count, parentsPtr)
                    }
                }
            }.flatMap { self.instanciate(OID(outOID)) }
    }
}

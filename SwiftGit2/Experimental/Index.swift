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
	func index() -> Result<Index, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Index(pointer!) }, pointOfFailure: "git_repository_index") {
			git_repository_index(&pointer, self.pointer)
		}
	}
}

public extension Index {
	var entrycount : Int { git_index_entrycount(pointer) }

	func entries() -> Result<[IndexOld.Entry], NSError> {
		var entries = [IndexOld.Entry]()
		for i in 0..<entrycount {
			if let entry = git_index_get_byindex(pointer, i) {
				entries.append(IndexOld.Entry(entry: entry.pointee))
			}
		}
		return .success(entries)
	}
	
	func add(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		
		return _result((), pointOfFailure: "git_index_add_all") {
			git_index_add_all(pointer, &paths, 0, nil, nil)
		}
		.flatMap { self.write() }
	}
	
	func remove(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		
		return _result((), pointOfFailure: "git_index_add_all") {
			git_index_remove_all(pointer, &paths, nil, nil)
		}
		.flatMap { self.write() }
	}
	
	func clear() -> Result<(), NSError> {
		_result((), pointOfFailure: "git_index_clear") { git_index_clear(pointer) }
	}
	
	private func write() -> Result<(),NSError> {
		_result((), pointOfFailure: "git_index_write") { git_index_write(pointer) }
	}
	
	func getTreeOID() -> Result<git_oid, NSError> {
		var treeOID = git_oid() // out
		
		return _result({ treeOID }, pointOfFailure: "git_index_write_tree") {
			git_index_write_tree(&treeOID, self.pointer)
		}
	}
}

public extension Duo where T1 == Index, T2 == Repository {
	func commit(message: String, signature: Signature) -> Result<Commit, NSError> {
		let (index,repo) = self.value
		
		return index.getTreeOID()
			.flatMap { treeOID in
				
				return repo.headParentCommit()
				// If parrent commit exist
				.flatMap{ parentCommit in
					repo.commit(tree: OID(treeOID), parents: [parentCommit], message: message, signature: signature)
				}
				// if there are no parents: initial commit
				.flatMapError { _ in
					repo.commit(tree: OID(treeOID), parents: [], message: message, signature: signature)
				}
			}
	}
}

fileprivate extension Repository {
	/// If no parents write "[]"
	/// Perform a commit with arbitrary numbers of parent commits.
	public func commit( tree treeOID: OID, parents: [Commit], message: String, signature: Signature ) -> Result<Commit, NSError> {
		// create commit signature
		return signature.makeUnsafeSignature().flatMap { signature in
			defer { git_signature_free(signature) }
			
			let tree = try! gitTreeLookup(tree: treeOID).get()
			
			var msgBuf = git_buf()
			defer { git_buf_free(&msgBuf) }
			git_message_prettify(&msgBuf, message, 0, /* ascii for # */ 35)
			
			
			// libgit2 expects a C-like array of parent git_commit pointer
			let parentGitCommits: [OpaquePointer?] = parents.map { $0.pointer }

			let parentsContiguous = ContiguousArray(parentGitCommits)
			return parentsContiguous.withUnsafeBufferPointer { unsafeBuffer in
				var commitOID = git_oid()
				let parentsPtr = UnsafeMutablePointer(mutating: unsafeBuffer.baseAddress)
				
				let result = git_commit_create( &commitOID, self.pointer, "HEAD", signature, signature,
												"UTF-8", msgBuf.ptr, tree.pointer, parents.count, parentsPtr )
				
				//TODO: Can be optimized
				guard result == GIT_OK.rawValue else {
					return .failure(NSError(gitError: result, pointOfFailure: "git_commit_create"))
				}
				return self.instanciate(OID(commitOID))
			}
		}
	}

	private func gitTreeLookup(tree treeOID: OID) -> Result<Tree, NSError> {
		var tree: OpaquePointer? = nil
		var treeOIDCopy = treeOID.oid
		
		return _result( { Tree(tree!) } , pointOfFailure: "git_tree_lookup") {
			git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
		}
	}
}

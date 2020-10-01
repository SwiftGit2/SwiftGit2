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
			git_repository_index(&pointer, pointer)
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
// OLD commit code
//	/// Perform a commit of the staged files with the specified message and signature,
//	/// assuming we are not doing a merge and using the current tip as the parent.
//	func commit(message: String, signature: Signature) -> Result<Commit, NSError> {
//		let (index,repo) = self.value
//
//		var treeOID = git_oid() // out
//		let treeResult = git_index_write_tree(&treeOID, index.pointer)
//		guard treeResult == GIT_OK.rawValue else {
//			let err = NSError(gitError: treeResult, pointOfFailure: "git_index_write_tree")
//			return .failure(err)
//		}
//		var parentID = git_oid()
//		let nameToIDResult = git_reference_name_to_id(&parentID, repo.pointer, "HEAD")
//		if nameToIDResult == GIT_OK.rawValue {
//			let commit = repo.instanciate(OID(parentID)) as Result<Commit, NSError>
//			return commit.flatMap { parentCommit in
//				repo.commit(tree: OID(treeOID), parents: [parentCommit], message: message, signature: signature)
//			}
//		}
//
//		// if there are no parents: initial commit
//		return repo.commit(tree: OID(treeOID), parents: [], message: message, signature: signature)
//	}
	
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

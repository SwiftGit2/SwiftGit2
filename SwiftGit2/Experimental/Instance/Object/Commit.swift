//
//  CommitInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Commit : Object {
	public var pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_commit_free(pointer)
	}
	
	public var message 	: String 	{ String(validatingUTF8: git_commit_message(pointer)) ?? "" }
	public var author 	: Signature { Signature(git_commit_author(pointer).pointee) }
	public var commiter	: Signature { Signature(git_commit_committer(pointer).pointee) }
	public var time		: Date 		{ Date(timeIntervalSince1970: Double(git_commit_time(pointer))) }
}

public extension Commit {
	func getParentCount() ->  Result<Int, NSError> {
		var parentCount: Int32 = 0
		
		return  _result( { Int(parentCount) } , pointOfFailure: "git_commit_parentcount" ) {
			parentCount = Int32( git_commit_parentcount(self.pointer) )
			return parentCount
		}
	}
	
	func getParentCommit(index: Int) -> Result<Commit, NSError> {
		var parentCommitPointer: OpaquePointer? = nil
		defer {
			git_reference_free(parentCommitPointer)
		}
		
		return  _result({ Commit(parentCommitPointer!) }, pointOfFailure: "git_commit_parent" ) {
			git_commit_parent(&parentCommitPointer, self.pointer, UInt32(index))
		}
	}
	
	func getAllParents() -> Result<[Commit], NSError> {
		getParentCount()
			.flatMap { parentCount in
				if parentCount == 0 { return .success([]) }
					
				return (0...parentCount)
					.map{ idx in self.getParentCommit(index: idx) }
					.aggregateResult()
			}
	}
	
	func getTree() -> Result<Tree, NSError> {
		var treePoint: OpaquePointer? = nil
		
		return  _result( { Tree(treePoint!) } , pointOfFailure: "git_commit_tree" ) {
			git_commit_tree( &treePoint, self.pointer )
		}
	}
}

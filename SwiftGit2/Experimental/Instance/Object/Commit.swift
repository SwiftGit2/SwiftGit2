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
	func parents() -> Result<[Commit], NSError> {
		var result: [Commit] = []
		let parentsCount = git_commit_parentcount(self.pointer)
		
		
		for i in 0..<parentsCount {
			var commit: OpaquePointer? = nil
			let gitResult = git_commit_parent(&commit, self.pointer, i )
			
			if gitResult == GIT_OK.rawValue {
				result.append(Commit(commit!))
			} else {
				return Result.failure(NSError(gitError: gitResult, pointOfFailure: "git_commit_parent"))
			}
		}
		
		return .success(result)
	}
	
	func getTree() -> Result<Tree, NSError> {
		var treePoint: OpaquePointer? = nil
		
		return  _result( { Tree(treePoint!) } , pointOfFailure: "git_commit_tree" ) {
			git_commit_tree( &treePoint, self.pointer )
		}
	}
}

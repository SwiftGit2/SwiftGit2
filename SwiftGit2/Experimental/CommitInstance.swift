//
//  CommitInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2


public class CommitInstance : ObjectProtocol {
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

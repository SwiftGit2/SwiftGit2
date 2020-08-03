//
//  Instance+Commit.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

extension Commit : InstanceType {
	public func free(pointer: OpaquePointer) {
		git_commit_free(pointer)
	}
}

public extension Instance where Type == Commit {
	var message 	: String 	{ String(validatingUTF8: git_commit_message(pointer)) ?? "" }
	var author 		: Signature { Signature(git_commit_author(pointer).pointee) }
	var commiter	: Signature { Signature(git_commit_committer(pointer).pointee) }
	var time		: Date 		{ Date(timeIntervalSince1970: Double(git_commit_time(pointer))) }
}

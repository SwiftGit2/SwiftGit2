//
//  Objects.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

/// A git object.
public protocol Object {
	/// The OID of the object.
	var oid: OID { get }
}

/// A git commit.
public struct Commit: Object {
	public let oid: OID
	public let message: String
	
	/// Create an instance with a libgit2 `git_commit` object.
	public init(pointer: COpaquePointer) {
		oid = OID(oid: git_object_id(pointer).memory)
		message = String.fromCString(git_commit_message(pointer))!
	}
}

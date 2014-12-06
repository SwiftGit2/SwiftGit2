//
//  Objects.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation

/// A git object.
public protocol Object {
	/// The OID of the object.
	var oid: OID { get }
}

public struct Signature {
	/// The name of the person.
	public let name: String
	
	/// The email of the person.
	public let email: String
	
	/// The time when the action happened.
	public let time: NSDate
	
	/// The time zone that `time` should be interpreted relative to.
	public let timeZone: NSTimeZone
	
	/// Create an instance with a libgit2 `git_signature`.
	public init(signature: git_signature) {
		name = String.fromCString(signature.name)!
		email = String.fromCString(signature.email)!
		time = NSDate(timeIntervalSince1970: NSTimeInterval(signature.when.time))
		timeZone = NSTimeZone(forSecondsFromGMT: NSInteger(60 * signature.when.offset))
	}
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

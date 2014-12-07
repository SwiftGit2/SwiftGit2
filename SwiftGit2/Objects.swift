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

extension Signature: Hashable {
	public var hashValue: Int {
		return name.hashValue ^ email.hashValue ^ Int(time.timeIntervalSince1970)
	}
}

public func == (lhs: Signature, rhs: Signature) -> Bool {
	return lhs.name == rhs.name
		&& lhs.email == rhs.email
		&& lhs.time == rhs.time
		&& lhs.timeZone.secondsFromGMT == rhs.timeZone.secondsFromGMT
}

/// A git commit.
public struct Commit: Object {
	/// The OID of the commit.
	public let oid: OID
	
	/// The OID of the commit's tree.
	public let tree: OID
	
	/// The OIDs of the commit's parents.
	public let parents: [OID]
	
	/// The author of the commit.
	public let author: Signature
	
	/// The committer of the commit.
	public let committer: Signature
	
	/// The full message of the commit.
	public let message: String
	
	/// Create an instance with a libgit2 `git_commit` object.
	public init(pointer: COpaquePointer) {
		oid = OID(oid: git_object_id(pointer).memory)
		message = String.fromCString(git_commit_message(pointer))!
		author = Signature(signature: git_commit_author(pointer).memory)
		committer = Signature(signature: git_commit_committer(pointer).memory)
		tree = OID(oid: git_commit_tree_id(pointer).memory)
		
		var parents: [OID] = []
		for idx in 0..<git_commit_parentcount(pointer) {
			let oid = git_commit_parent_id(pointer, idx).memory
			parents.append(OID(oid: oid))
		}
		self.parents = parents
	}
}

//
//  Objects.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation

/// A git object.
public protocol ObjectType {
	static var type: git_otype { get }
	
	/// The OID of the object.
	var oid: OID { get }
	
	/// Create an instance with the underlying libgit2 type.
	init(_ pointer: COpaquePointer)
}

public func == <O: ObjectType>(lhs: O, rhs: O) -> Bool {
	return lhs.oid == rhs.oid
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
	public init(_ signature: git_signature) {
		name = String.fromCString(signature.name)!
		email = String.fromCString(signature.email)!
		time = NSDate(timeIntervalSince1970: NSTimeInterval(signature.when.time))
		timeZone = NSTimeZone(forSecondsFromGMT: NSInteger(60 * signature.when.offset))
	}
}

extension Signature: Hashable {
	public var hashValue: Int {
		return name.hashValue ^ email.hashValue ^ time.timeIntervalSince1970.hashValue
	}
}

public func == (lhs: Signature, rhs: Signature) -> Bool {
	return lhs.name == rhs.name
		&& lhs.email == rhs.email
		&& lhs.time == rhs.time
		&& lhs.timeZone.secondsFromGMT == rhs.timeZone.secondsFromGMT
}

/// A git commit.
public struct Commit: ObjectType {
	public static let type = GIT_OBJ_COMMIT
	
	/// The OID of the commit.
	public let oid: OID
	
	/// The OID of the commit's tree.
	public let tree: PointerTo<Tree>
	
	/// The OIDs of the commit's parents.
	public let parents: [PointerTo<Commit>]
	
	/// The author of the commit.
	public let author: Signature
	
	/// The committer of the commit.
	public let committer: Signature
	
	/// The full message of the commit.
	public let message: String
	
	/// Create an instance with a libgit2 `git_commit` object.
	public init(_ pointer: COpaquePointer) {
		oid = OID(git_object_id(pointer).memory)
		message = String.fromCString(git_commit_message(pointer))!
		author = Signature(git_commit_author(pointer).memory)
		committer = Signature(git_commit_committer(pointer).memory)
		tree = PointerTo(OID(git_commit_tree_id(pointer).memory))
		
		self.parents = map(0..<git_commit_parentcount(pointer)) {
			return PointerTo(OID(git_commit_parent_id(pointer, $0).memory))
		}
	}
}

extension Commit: Hashable {
	public var hashValue: Int {
		return self.oid.hashValue
	}
}

/// A git tree.
public struct Tree: ObjectType {
	public static let type = GIT_OBJ_TREE
	
	/// An entry in a `Tree`.
	public struct Entry {
		/// The entry's UNIX file attributes.
		public let attributes: Int32
		
		/// The object pointed to by the entry.
		public let object: Pointer
		
		/// The file name of the entry.
		public let name: String
		
		/// Create an instance with a libgit2 `git_tree_entry`.
		public init(_ pointer: COpaquePointer) {
			let oid = OID(git_tree_entry_id(pointer).memory)
			attributes = Int32(git_tree_entry_filemode(pointer).value)
			object = Pointer(oid: oid, type: git_tree_entry_type(pointer))!
			name = String.fromCString(git_tree_entry_name(pointer))!
		}
		
		/// Create an instance with the individual values.
		public init(attributes: Int32, object: Pointer, name: String) {
			self.attributes = attributes
			self.object = object
			self.name = name
		}
	}

	/// The OID of the tree.
	public let oid: OID
	
	/// The entries in the tree.
	public let entries: [String: Entry]
	
	/// Create an instance with a libgit2 `git_tree`.
	public init(_ pointer: COpaquePointer) {
		oid = OID(git_object_id(pointer).memory)
		
		var entries: [String: Entry] = [:]
		for idx in 0..<git_tree_entrycount(pointer) {
			let entry = Entry(git_tree_entry_byindex(pointer, idx))
			entries[entry.name] = entry
		}
		self.entries = entries
	}
}

extension Tree.Entry: Hashable {
	public var hashValue: Int {
		return Int(attributes) ^ object.hashValue ^ name.hashValue
	}
}

extension Tree.Entry: Printable {
	public var description: String {
		return "\(attributes) \(object) \(name)"
	}
}

public func == (lhs: Tree.Entry, rhs: Tree.Entry) -> Bool {
	return lhs.attributes == rhs.attributes
		&& lhs.object == rhs.object
		&& lhs.name == rhs.name
}

extension Tree: Hashable {
	public var hashValue: Int {
		return oid.hashValue
	}
}

/// A git blob.
public struct Blob: ObjectType {
	public static let type = GIT_OBJ_BLOB
	
	/// The OID of the blob.
	public let oid: OID
	
	/// The contents of the blob.
	public let data: NSData
	
	/// Create an instance with a libgit2 `git_blob`.
	public init(_ pointer: COpaquePointer) {
		oid = OID(git_object_id(pointer).memory)
		
		// Swift doesn't get the types right without `Int(Int64(...))` :(
		let length = Int(Int64(git_blob_rawsize(pointer).value))
		data = NSData(bytes: git_blob_rawcontent(pointer), length: length)
	}
}

extension Blob: Hashable {
	public var hashValue: Int {
		return oid.hashValue
	}
}

/// An annotated git tag.
public struct Tag: ObjectType {
	public static let type = GIT_OBJ_TAG
	
	/// The OID of the tag.
	public let oid: OID
	
	/// The tagged object.
	public let target: Pointer
	
	/// The name of the tag.
	public let name: String
	
	/// The tagger (author) of the tag.
	public let tagger: Signature
	
	/// The message of the tag.
	public let message: String
	
	/// Create an instance with a libgit2 `git_tag`.
	public init(_ pointer: COpaquePointer) {
		oid = OID(git_object_id(pointer).memory)
		let targetOID = OID(git_tag_target_id(pointer).memory)
		target = Pointer(oid: targetOID, type: git_tag_target_type(pointer))!
		name = String.fromCString(git_tag_name(pointer))!
		tagger = Signature(git_tag_tagger(pointer).memory)
		message = String.fromCString(git_tag_message(pointer))!
	}
}

extension Tag: Hashable {
	public var hashValue: Int {
		return oid.hashValue
	}
}

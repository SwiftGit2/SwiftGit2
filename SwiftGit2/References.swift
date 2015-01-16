//
//  References.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/2/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

/// A reference to a git object.
public protocol ReferenceType {
	/// The full name of the reference (e.g., `refs/heads/master`).
	var longName: String { get }
	
	/// The short human-readable name of the reference if one exists (e.g., `master`).
	var shortName: String? { get }
	
	/// The OID of the referenced object.
	var oid: OID { get }
}

/// A generic reference to a git object.
public struct Reference: ReferenceType {
	/// The full name of the reference (e.g., `refs/heads/master`).
	public let longName: String
	
	/// The short human-readable name of the reference if one exists (e.g., `master`).
	public let shortName: String?
	
	/// The OID of the referenced object.
	public let oid: OID
	
	/// Create an instance with a libgit2 `git_reference` object.
	public init(_ pointer: COpaquePointer) {
		let shorthand = String.fromCString(git_reference_shorthand(pointer))!
		longName = String.fromCString(git_reference_name(pointer))!
		shortName = (shorthand == longName ? nil : shorthand)
		oid = OID(git_reference_target(pointer).memory)
	}
}

/// A git branch.
public struct Branch: ReferenceType {
	/// The full name of the reference (e.g., `refs/heads/master`).
	public let longName: String
	
	/// The name of the remote this branch belongs to, or nil if it's a local branch.
	public let remoteName: String?
	
	/// The short human-readable name of the branch (e.g., `master`).
	public let name: String
	
	/// A pointer to the referenced commit.
	public let commit: PointerTo<Commit>
	
	// MARK: Derived Properties
	
	/// The short human-readable name of the branch (e.g., `master`).
	///
	/// This is the same as `name`, but is declared with an Optional type to adhere to
	/// `ReferenceType`.
	public var shortName: String? { return name }
	
	/// The OID of the referenced object.
	///
	/// This is the same as `commit.oid`, but is declared here to adhere to `ReferenceType`.
	public var oid: OID { return commit.oid }
}

/// A git tag reference, which can be either a lightweight tag or a Tag object.
public enum TagReference: ReferenceType {
	/// A lightweight tag, which is just a name and an OID.
	case Lightweight(String, OID)
	
	/// An annotated tag, which points to a Tag object.
	case Annotated(String, Tag)
	
	/// The full name of the reference (e.g., `refs/tags/my-tag`).
	public var longName: String {
		switch self {
		case let .Lightweight(name, _):
			return name
		case let .Annotated(name, _):
			return name
		}
	}
	
	/// The short human-readable name of the branch (e.g., `master`).
	public var name: String {
		return longName.substringFromIndex("refs/tags/".endIndex)
	}
	
	/// The OID of the target object.
	///
	/// If this is an annotated tag, the OID will be the tag's target.
	public var oid: OID {
		switch self {
		case let .Lightweight(_, oid):
			return oid
		case let .Annotated(_, tag):
			return tag.target.oid
		}
	}
	
	// MARK: Derived Properties
	
	/// The short human-readable name of the branch (e.g., `master`).
	///
	/// This is the same as `name`, but is declared with an Optional type to adhere to
	/// `ReferenceType`.
	public var shortName: String? { return name }
}



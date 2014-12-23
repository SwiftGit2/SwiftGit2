//
//  Pointers.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/23/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation

import Foundation

/// A pointer to a git object.
public protocol PointerType: Equatable, Hashable {
	/// The OID of the referenced object.
	var oid: OID { get }
	
	/// The libgit2 `git_otype` of the referenced object.
	var type: git_otype { get }
}

public func == <P: PointerType>(lhs: P, rhs: P) -> Bool {
	return lhs.oid == rhs.oid && lhs.type.value == rhs.type.value
}

/// A pointer to a git object.
public enum Pointer: PointerType {
	case Commit(OID)
	case Tree(OID)
	case Blob(OID)
	case Tag(OID)
	
	public var oid: OID {
		switch self {
		case let Commit(oid):
			return oid
		case let Tree(oid):
			return oid
		case let Blob(oid):
			return oid
		case let Tag(oid):
			return oid
		}
	}
	
	public var type: git_otype {
		switch self {
		case let Commit(oid):
			return GIT_OBJ_COMMIT
		case let Tree(oid):
			return GIT_OBJ_TREE
		case let Blob(oid):
			return GIT_OBJ_BLOB
		case let Tag(oid):
			return GIT_OBJ_TAG
		}
	}
	
	/// Create an instance with an OID and a libgit2 `git_otype`.
	init?(oid: OID, type: git_otype) {
		switch type.value {
		case GIT_OBJ_COMMIT.value:
			self = Commit(oid)
		case GIT_OBJ_TREE.value:
			self = Tree(oid)
		case GIT_OBJ_BLOB.value:
			self = Blob(oid)
		case GIT_OBJ_TAG.value:
			self = Tag(oid)
		default:
			return nil
		}
	}
}

extension Pointer: Hashable {
	public var hashValue: Int {
		return oid.hashValue
	}
}

extension Pointer: Printable {
	public var description: String {
		switch self {
		case Commit:
			return "commit(\(oid))"
		case Tree:
			return "tree(\(oid))"
		case Blob:
			return "blob(\(oid))"
		case Tag:
			return "tag(\(oid))"
		}
	}
}

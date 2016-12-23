//
//  Pointers.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/23/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import libgit2

/// A pointer to a git object.
public protocol PointerType: Equatable, Hashable {
	/// The OID of the referenced object.
	var oid: OID { get }

	/// The libgit2 `git_otype` of the referenced object.
	var type: git_otype { get }
}

public func == <P: PointerType>(lhs: P, rhs: P) -> Bool {
	return lhs.oid == rhs.oid && lhs.type.rawValue == rhs.type.rawValue
}

/// A pointer to a git object.
public enum Pointer: PointerType {
	case Commit(OID)
	case Tree(OID)
	case Blob(OID)
	case Tag(OID)

	public var oid: OID {
		switch self {
		case let .Commit(oid):
			return oid
		case let .Tree(oid):
			return oid
		case let .Blob(oid):
			return oid
		case let .Tag(oid):
			return oid
		}
	}

	public var type: git_otype {
		switch self {
		case .Commit:
			return GIT_OBJ_COMMIT
		case .Tree:
			return GIT_OBJ_TREE
		case .Blob:
			return GIT_OBJ_BLOB
		case .Tag:
			return GIT_OBJ_TAG
		}
	}

	/// Create an instance with an OID and a libgit2 `git_otype`.
	init?(oid: OID, type: git_otype) {
		switch type {
		case GIT_OBJ_COMMIT:
			self = .Commit(oid)
		case GIT_OBJ_TREE:
			self = .Tree(oid)
		case GIT_OBJ_BLOB:
			self = .Blob(oid)
		case GIT_OBJ_TAG:
			self = .Tag(oid)
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

extension Pointer: CustomStringConvertible {
	public var description: String {
		switch self {
		case .Commit:
			return "commit(\(oid))"
		case .Tree:
			return "tree(\(oid))"
		case .Blob:
			return "blob(\(oid))"
		case .Tag:
			return "tag(\(oid))"
		}
	}
}

public struct PointerTo<T: ObjectType>: PointerType {
	public let oid: OID

	public var type: git_otype {
		return T.type
	}

	public init(_ oid: OID) {
		self.oid = oid
	}
}

extension PointerTo: Hashable {
	public var hashValue: Int {
		return oid.hashValue
	}
}

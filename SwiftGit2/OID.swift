//
//  OID.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/17/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

/// An identifier for a Git object.
public struct OID {
	
	public static func create(from string: String) -> Result<OID,Error> {
		if string.lengthOfBytes(using: String.Encoding.ascii) > 40 {
			return .failure(WTF("string length > 40"))
		}
		
		var oid = git_oid()
		
		return git_try("git_oid_fromstr") { git_oid_fromstr(&oid, string) }
			.map { OID(oid) }
	}

	// MARK: - Initializers

	/// Create an instance from a hex formatted string.
	///
	/// string - A 40-byte hex formatted string.
	public init?(string: String) {
		// libgit2 doesn't enforce a maximum length
		if string.lengthOfBytes(using: String.Encoding.ascii) > 40 {
			return nil
		}

		
		
		let pointer = UnsafeMutablePointer<git_oid>.allocate(capacity: 1)
		let result = git_oid_fromstr(pointer, string)

		if result < GIT_OK.rawValue {
			pointer.deallocate()
			return nil
		}

		oid = pointer.pointee
		pointer.deallocate()
	}

	/// Create an instance from a libgit2 `git_oid`.
	public init(_ oid: git_oid) {
		self.oid = oid
	}

	// MARK: - Properties

	public let oid: git_oid
}

extension OID: CustomStringConvertible {
	public var description: String {
		let length = Int(GIT_OID_RAWSZ) * 2
		let string = UnsafeMutablePointer<Int8>.allocate(capacity: length)
		var oid = self.oid
		git_oid_fmt(string, &oid)

		return String(bytesNoCopy: string, length: length, encoding: .ascii, freeWhenDone: true)!
	}
}

extension OID: Hashable {
	public func hash(into hasher: inout Hasher) {
		withUnsafeBytes(of: oid.id) {
			hasher.combine(bytes: $0)
		}
	}

	public static func == (lhs: OID, rhs: OID) -> Bool {
		var left = lhs.oid
		var right = rhs.oid
		return git_oid_cmp(&left, &right) == 0
	}
}

public extension Duo where T1 == OID, T2 == Repository {
	func commit() -> Result<Commit, Error> {
		let (oid, repo) = self.value
		return repo.instanciate(oid)
	}
}

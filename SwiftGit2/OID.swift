//
//  OID.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/17/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import LlamaKit

/// An identifier for a Git object.
public struct OID {
	
	// MARK: - Initializers
	
	/// Create an instance from a hex formatted string.
	///
	/// string - A 40-byte hex formatted string.
	public init?(string: String) {
		// libgit2 doesn't enforce a maximum length
		if (string.lengthOfBytesUsingEncoding(NSASCIIStringEncoding) > 40) {
			return nil
		}
		
		let pointer = UnsafeMutablePointer<git_oid>.alloc(1)
		let result = git_oid_fromstr(pointer, string.cStringUsingEncoding(NSASCIIStringEncoding)!)
		
		if result < GIT_OK.value {
			pointer.dealloc(1)
			return nil;
		}
		
		oid = pointer.memory;
		pointer.dealloc(1)
	}
	
	/// Create an instance from a libgit2 `git_oid`.
	public init(oid: git_oid) {
		self.oid = oid
	}
	
	// MARK: - Properties
	
	public let oid: git_oid
}

extension OID: Printable {
	public var description: String {
		let length = Int(GIT_OID_RAWSZ) * 2
		let string = UnsafeMutablePointer<Int8>.alloc(length)
		var oid = self.oid
		git_oid_fmt(string, &oid)
		
		return String(bytesNoCopy: string, length: length, encoding: NSASCIIStringEncoding, freeWhenDone: true)!
	}
}

extension OID: Hashable {
	public var hashValue: Int {
		return Int(self.oid.id.0) ^ Int(self.oid.id.1) ^ Int(self.oid.id.2)
	}
}

public func == (lhs: OID, rhs: OID) -> Bool {
	var left = lhs.oid
	var right = rhs.oid
	return git_oid_cmp(&left, &right) == 0
}

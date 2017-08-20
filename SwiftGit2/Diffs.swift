//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

public struct GitDiffFile {
	public var oid: OID
	public var path: String
	public var size: Int64
	public var flags: UInt32
}

public enum GitDeltaStatus: Int {
	case current
	case indexNew
	case indexModified
	case indexDeleted
	case indexRenamed
	case indexTypeChange
	case workTreeNew
	case workTreeModified
	case workTreeDeleted
	case workTreeTypeChange
	case workTreeRenamed
	case workTreeUnreadable
	case ignored
	case conflicted

	public var value: UInt32 {
		if self.rawValue == 0 {
			return UInt32(0)
		}
		return UInt32(1 << (self.rawValue - 1))
	}
}

public struct GitDiffDelta {
	public var status: GitDeltaStatus
	public var flags: UInt32
	public var oldFile: GitDiffFile
	public var newFile: GitDiffFile
}

public enum GitDiffFlag: Int {
	case binary
	case notBinary
	case validId
	case exists

	public var value: UInt32 {
		if self.rawValue == 0 {
			return UInt32(0)
		}
		return UInt32(1 << (self.rawValue - 1))
	}
}


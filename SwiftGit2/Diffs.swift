//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

public struct GitDiffFile {
	var oid: OID
	var path: String
	var size: Int64
	var flags: UInt32
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

	var value: UInt32 {
		if self.rawValue == 0 {
			return UInt32(0)
		}
		return UInt32(1 << (self.rawValue - 1))
	}
}

public struct GitDiffDelta {
	var status: GitDeltaStatus
	var flags: UInt32
	var oldFile: GitDiffFile
	var newFile: GitDiffFile
}

public enum GitDiffFlag: Int {
	case binary
	case notBinary
	case validId
	case exists

	var value: UInt32 {
		if self.rawValue == 0 {
			return UInt32(0)
		}
		return UInt32(1 << (self.rawValue - 1))
	}
}


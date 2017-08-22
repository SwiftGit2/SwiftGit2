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

public enum GitStatus: Int {
	case current                = 0
	case indexNew               = 1
	case indexModified          = 2
	case indexDeleted           = 4
	case indexRenamed           = 8
	case indexTypeChange        = 16
	case workTreeNew            = 32
	case workTreeModified       = 64
	case workTreeDeleted        = 128
	case workTreeTypeChange     = 256
	case workTreeRenamed        = 512
	case workTreeUnreadable     = 1024
	case ignored                = 2048
	case conflicted             = 4096

	public var value: UInt32 {
		return UInt32(self.rawValue)
	}
}

public struct GitDiffDelta {
	public var status: GitStatus?
	public var flags: UInt32?
	public var oldFile: GitDiffFile?
	public var newFile: GitDiffFile?
}

public enum GitDiffFlag: Int {
	case binary     = 0
	case notBinary  = 1
	case validId    = 2
	case exists     = 4

	public var value: UInt32 {
		return UInt32(self.rawValue)
	}
}

public struct GitStatusEntry {
	public var status: GitStatus?
	public var headToIndex: GitDiffDelta?
	public var indexToWorkDir: GitDiffDelta?
}

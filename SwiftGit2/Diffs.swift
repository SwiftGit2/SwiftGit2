//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//
import libgit2

public struct DiffFile {
	public var oid: OID
	public var path: String
	public var size: Int64
	public var flags: UInt32
}

public struct StatusEntry {
	public var status: Status?
	public var headToIndex: DiffDelta?
	public var indexToWorkDir: DiffDelta?
}

public struct Status: OptionSet {
	// This appears to be necessary due to bug in Swift
	// https://bugs.swift.org/browse/SR-3003
	public init(rawValue: UInt32) {
		self.rawValue = rawValue
	}
	public let rawValue: UInt32

	static let current                = Status(rawValue:  0)
	static let indexNew               = Status(rawValue:  1 << 0)
	static let indexModified          = Status(rawValue:  1 << 1)
	static let indexDeleted           = Status(rawValue:  1 << 2)
	static let indexRenamed           = Status(rawValue:  1 << 3)
	static let indexTypeChange        = Status(rawValue:  1 << 4)
	static let workTreeNew            = Status(rawValue:  1 << 5)
	static let workTreeModified       = Status(rawValue:  1 << 6)
	static let workTreeDeleted        = Status(rawValue:  1 << 7)
	static let workTreeTypeChange     = Status(rawValue:  1 << 8)
	static let workTreeRenamed        = Status(rawValue:  1 << 9)
	static let workTreeUnreadable     = Status(rawValue:  1 << 10)
	static let ignored                = Status(rawValue:  1 << 11)
	static let conflicted             = Status(rawValue:  1 << 12)
}

public struct DiffFlag: OptionSet {
	// This appears to be necessary due to bug in Swift
	// https://bugs.swift.org/browse/SR-3003
	public init(rawValue: UInt32) {
		self.rawValue = rawValue
	}
	public let rawValue: UInt32

	static let binary     = DiffFlag(rawValue: 0)
	static let notBinary  = DiffFlag(rawValue: 1 << 0)
	static let validId    = DiffFlag(rawValue: 1 << 1)
	static let exists     = DiffFlag(rawValue: 1 << 2)
}

public struct DiffDelta {
	public var status: Status?
	public var flags: DiffFlag?
	public var oldFile: DiffFile?
	public var newFile: DiffFile?

	public init(from diffDelta: git_diff_delta) {
		let emptyOid = OID(string: "0000000000000000000000000000000000000000")
		let oldOid = OID(diffDelta.old_file.id)
		let newOid = OID(diffDelta.old_file.id)

		// Because of the way git diffs work, new or deleted files can have confusing statuses
		// We're simplifying that here by checking directly
		if newOid == emptyOid {
			self.status = Status.indexDeleted
		} else if oldOid == emptyOid {
			self.status = Status.indexNew
		} else {
			self.status = DiffDelta.convertStatus(diffDelta.status.rawValue)
		}
		self.flags = DiffFlag(rawValue: diffDelta.flags)
		self.oldFile = self.convertDiffFile(diffDelta.old_file)
		self.newFile = self.convertDiffFile(diffDelta.new_file)
	}

	static func convertStatus(_ statusValue: UInt32) -> Status {
		var status: Status? = nil

		// Index status
		if (statusValue & GIT_STATUS_INDEX_NEW.rawValue) == GIT_STATUS_INDEX_NEW.rawValue {
			status = Status.indexNew
		} else if (statusValue & GIT_STATUS_INDEX_MODIFIED.rawValue) == GIT_STATUS_INDEX_MODIFIED.rawValue {
			status = Status.indexModified
		} else if (statusValue & GIT_STATUS_INDEX_DELETED.rawValue) == GIT_STATUS_INDEX_DELETED.rawValue {
			status = Status.indexDeleted
		} else if (statusValue & GIT_STATUS_INDEX_RENAMED.rawValue) == GIT_STATUS_INDEX_RENAMED.rawValue {
			status = Status.indexRenamed
		} else if (statusValue & GIT_STATUS_INDEX_TYPECHANGE.rawValue) == GIT_STATUS_INDEX_TYPECHANGE.rawValue {
			status = Status.indexTypeChange
		}

		// Worktree status
		if (statusValue & GIT_STATUS_WT_NEW.rawValue) == GIT_STATUS_WT_NEW.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeNew.rawValue)
		} else if (statusValue & GIT_STATUS_WT_MODIFIED.rawValue) == GIT_STATUS_WT_MODIFIED.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeModified.rawValue)
		} else if (statusValue & GIT_STATUS_WT_DELETED.rawValue) == GIT_STATUS_WT_DELETED.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeDeleted.rawValue)
		} else if (statusValue & GIT_STATUS_WT_RENAMED.rawValue) == GIT_STATUS_WT_RENAMED.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeRenamed.rawValue)
		} else if (statusValue & GIT_STATUS_WT_TYPECHANGE.rawValue) == GIT_STATUS_WT_TYPECHANGE.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeTypeChange.rawValue)
		}

		return status!
	}

	private func convertDiffFile(_ file: git_diff_file) -> DiffFile {
		let path = file.path
		let newFile = DiffFile(oid: OID(file.id),
		                       path: path.map(String.init(cString:))!,
		                       size: file.size,
		                       flags: file.flags)
		return newFile
	}
}

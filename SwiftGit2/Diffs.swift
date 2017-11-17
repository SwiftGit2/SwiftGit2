//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//
import libgit2

public struct StatusEntry {
	public var status: Diff.Status
	public var headToIndex: Diff.Delta?
	public var indexToWorkDir: Diff.Delta?

	public init(from statusEntry: git_status_entry) {
		self.status = Diff.Status(rawValue: statusEntry.status.rawValue)

		if let htoi = statusEntry.head_to_index {
			self.headToIndex = Diff.Delta(_: htoi.pointee)
		}

		if let itow = statusEntry.index_to_workdir {
			self.indexToWorkDir = Diff.Delta(_: itow.pointee)
		}
	}
}

public struct Diff {
	public struct File {
		public var oid: OID
		public var path: String
		public var size: Int64
		public var flags: Flags

		public init(_ diffFile: git_diff_file) {
			self.oid = OID(diffFile.id)
			let path = diffFile.path
			self.path = path.map(String.init(cString:))!
			self.size = diffFile.size
			self.flags = Flags(rawValue: diffFile.flags)
		}
	}

	public struct Status: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let current                = Status(rawValue: 0)
		public static let indexNew               = Status(rawValue: 1 << 0)
		public static let indexModified          = Status(rawValue: 1 << 1)
		public static let indexDeleted           = Status(rawValue: 1 << 2)
		public static let indexRenamed           = Status(rawValue: 1 << 3)
		public static let indexTypeChange        = Status(rawValue: 1 << 4)
		public static let workTreeNew            = Status(rawValue: 1 << 5)
		public static let workTreeModified       = Status(rawValue: 1 << 6)
		public static let workTreeDeleted        = Status(rawValue: 1 << 7)
		public static let workTreeTypeChange     = Status(rawValue: 1 << 8)
		public static let workTreeRenamed        = Status(rawValue: 1 << 9)
		public static let workTreeUnreadable     = Status(rawValue: 1 << 10)
		public static let ignored                = Status(rawValue: 1 << 11)
		public static let conflicted             = Status(rawValue: 1 << 12)
	}

	public struct Flags: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let binary     = Flags(rawValue: 0)
		public static let notBinary  = Flags(rawValue: 1 << 0)
		public static let validId    = Flags(rawValue: 1 << 1)
		public static let exists     = Flags(rawValue: 1 << 2)
	}

	public struct Delta {
		public var status: Status
		public var flags: Flags
		public var oldFile: File?
		public var newFile: File?

		public init(_ delta: git_diff_delta) {
			self.status = Status(rawValue: delta.status.rawValue)
			self.flags = Flags(rawValue: delta.flags)
			self.oldFile = File(_: delta.old_file)
			self.newFile = File(_: delta.new_file)
		}
	}
}

//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

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

public struct DiffDelta {
	public var status: Status?
	public var flags: UInt32?
	public var oldFile: DiffFile?
	public var newFile: DiffFile?
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

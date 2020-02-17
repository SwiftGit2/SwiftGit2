//
//  Repository+Apply.swift
//  SwiftGit2-OSX
//
//  Created by Serhii Vynnychenko on 2/17/20.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public enum GitApplyLocation : UInt32 {
	case workdir = 0
	case index = 1
	case both = 2
}

public extension Repository {
	func apply(diff: Diff, location: GitApplyLocation, options: GitApplyOptions?) -> Result<(), NSError> {
		return _result((), pointOfFailure: "git_apply") {
			git_apply(pointer, diff.pointer, git_apply_location_t(rawValue: location.rawValue), options?.pointer)
		}
	}
}

public class GitApplyOptions {
	var pointer = UnsafeMutablePointer<git_apply_options>.allocate(capacity: 1)
	
	public var version  : UInt32 { get { pointer.pointee.version } }
	
	public var flags 	: Flags { get { Flags(rawValue: pointer.pointee.flags) } set { pointer.pointee.flags = newValue.rawValue } }
	
	public var payload	: UnsafeMutableRawPointer?  { get { pointer.pointee.payload}	set { pointer.pointee.payload = newValue } }
	public var delta_cb : git_apply_delta_cb 		{ get { pointer.pointee.delta_cb }	set { pointer.pointee.delta_cb = newValue }}
	public var hunk_cb  : git_apply_hunk_cb 		{ get { pointer.pointee.hunk_cb }	set { pointer.pointee.hunk_cb = newValue } }
	
	public init() {
		let result = git_apply_options_init(pointer, UInt32(GIT_APPLY_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
	}
	
	deinit {
		pointer.deallocate()
	}
}

public extension GitApplyOptions {
	struct Flags : OptionSet {
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32
		
		public static let None = Flags(rawValue: GIT_APPLY_CHECK.rawValue)
	}
}

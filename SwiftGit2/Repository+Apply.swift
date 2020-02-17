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

public class GitApplyOptions {
	var options : git_apply_options
	
	public var version  : UInt32 { get { options.version } }
	
	public var flags 	: Flags { get { Flags(rawValue: options.flags) } set { options.flags = newValue.rawValue } }
	
	public var payload	: UnsafeMutableRawPointer?  { get { options.payload} set { options.payload = newValue } }
	public var delta_cb :  git_apply_delta_cb { get { options.delta_cb } set { options.delta_cb = newValue }}
	public var hunk_cb : git_apply_hunk_cb { get { options.hunk_cb } set { options.hunk_cb = newValue } }
	
	public init() {
		let pointer = UnsafeMutablePointer<git_apply_options>.allocate(capacity: 1)
		git_apply_options_init(pointer, UInt32(GIT_APPLY_OPTIONS_VERSION))
		options = pointer.move()
		pointer.deallocate()
	}
}

public extension Repository {
	func apply(diff: Diff, location: GitApplyLocation) -> Result<(), NSError> {
		return _result((), pointOfFailure: "git_apply") {
			git_apply(pointer, diff.pointer, git_apply_location_t(rawValue: location.rawValue), nil)
		}
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

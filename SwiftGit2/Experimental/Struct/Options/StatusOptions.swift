//
//  StatusOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 12.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public struct StatusOptions {
	var git_options = git_status_options()
	
	var version		: UInt32 { git_options.version }
	var show		: StatusOptions.Show { StatusOptions.Show(rawValue: git_options.show.rawValue)! }
	var flags		: StatusOptions.Flags { StatusOptions.Flags(rawValue: git_options.flags) }
	
	
	public init(flags: StatusOptions.Flags? = nil, show: StatusOptions.Show? = nil, pathspec: [String] = []) {
		withUnsafeMutablePointer(to: &git_options) { pointer in
			let result = git_status_init_options(pointer, UInt32(GIT_STATUS_OPTIONS_VERSION))
			assert(result == GIT_OK.rawValue)
		}
		
		if !pathspec.isEmpty {
			git_options.pathspec = git_strarray(strings: pathspec)
		}
		
		if let flags = flags {
			git_options.flags = flags.rawValue
		}
		
		if let show = show {
			git_options.show = git_status_show_t(rawValue: show.rawValue)
		}
	}
}

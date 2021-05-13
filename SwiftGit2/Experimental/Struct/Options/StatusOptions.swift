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
	private var git_options = git_status_options()
	var pathspec = [String]()
	
	var version		: UInt32 { git_options.version }
	var show		: StatusOptions.Show { StatusOptions.Show(rawValue: git_options.show.rawValue)! }
	var flags		: StatusOptions.Flags { StatusOptions.Flags(rawValue: git_options.flags) }
	
	
	public init(flags: StatusOptions.Flags? = nil, show: StatusOptions.Show? = nil, pathspec: [String] = []) {
		self.pathspec = pathspec
		let result = git_status_init_options(&git_options, UInt32(GIT_STATUS_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		if let flags = flags {
			git_options.flags = flags.rawValue
		}
		
		if let show = show {
			git_options.show = git_status_show_t(rawValue: show.rawValue)
		}
	}
}

extension StatusOptions {
	mutating func with_git_status_options<T>(_ body: (inout git_status_options) -> T) -> T {
		if pathspec.isEmpty {
			return body(&git_options)
		} else {
			return pathspec.with_git_strarray { strarray in
				git_options.pathspec = strarray
				return body(&git_options)
			}
		}
	}
}

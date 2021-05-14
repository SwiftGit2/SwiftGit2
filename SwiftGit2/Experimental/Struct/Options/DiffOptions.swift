//
//  DiffOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class DiffOptions {
	var diff_options = git_diff_options()
		
	public init() {
		let result = git_diff_options_init(&diff_options, UInt32(GIT_DIFF_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
	}
}

//
//  MergeOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 12.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

struct MergeOptions {
	var merge_options = git_merge_options()
	
	public init(mergeFlags: git_merge_flag_t? = nil, fileFlags: git_merge_file_flag_t? = nil, renameTheshold: Int = 50) {
		let result = git_merge_init_options(&merge_options, UInt32(GIT_MERGE_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		if let mergeFlags = mergeFlags {
			merge_options.flags 	= mergeFlags.rawValue
		}
		
		if let fileFlags = fileFlags {
			merge_options.file_flags	= fileFlags.rawValue
		}
		
		merge_options.rename_threshold = UInt32( renameTheshold )
	}
}

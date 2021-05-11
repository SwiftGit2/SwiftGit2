//
//  SubmoduleUpdateOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 10.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class SubmoduleUpdateOptions {
	var options = git_submodule_update_options()
	
	public init () {
		git_submodule_update_options_init(&options, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION) )
	}
	
	public init (fetchOptions: FetchOptions) {
		git_submodule_update_options_init(&options, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION) )
		
		options.fetch_opts = fetchOptions.fetch_options
	}
}

//
//  CloneOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public struct CloneOptions {
	var clone_options = git_clone_options()
	
	var bare : Bool {
		set { clone_options.bare = newValue ? 1 : 0 }
		get { return clone_options.bare == 1 }
	}
	
	public init(fetch: FetchOptions = FetchOptions(), checkout: CheckoutOptions = CheckoutOptions()) {
		git_clone_init_options(&clone_options, UInt32(GIT_CLONE_OPTIONS_VERSION))
		
		//	options.local = GIT_CLONE_NO_LOCAL
		
		clone_options.fetch_opts = fetch.fetch_options
		clone_options.checkout_opts = checkout.checkout_options
	}
}

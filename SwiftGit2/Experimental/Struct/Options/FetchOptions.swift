//
//  FetchOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class FetchOptions {
	private var fetch_options = git_fetch_options()
	
	public init(callbacks: RemoteCallbacks = RemoteCallbacks()) {
		let result = git_fetch_options_init(&fetch_options, UInt32(GIT_FETCH_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		//self.callbacks = callbacks
		fetch_options.callbacks = callbacks.remote_callbacks
	}
	
	public convenience init(credentials: Credentials) {
		self.init(callbacks: RemoteCallbacks(credentials: credentials))
	}
}

extension FetchOptions {
	func with_git_fetch_options<T>(_ body: (inout git_fetch_options) -> T) -> T {

		return body(&fetch_options)
	}
}

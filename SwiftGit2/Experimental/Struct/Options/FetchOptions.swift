//
//  FetchOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public struct FetchOptions {
	var fetch_options = git_fetch_options()
	
	//let callbacks : RemoteCallbacks
	
	public init(callbacks: RemoteCallbacks = RemoteCallbacks()) {
		let result = git_fetch_options_init(&fetch_options, UInt32(GIT_FETCH_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		//self.callbacks = callbacks
		fetch_options.callbacks = callbacks.remote_callbacks
	}
	
	public init(credentials: Credentials) {
		self.init(callbacks: RemoteCallbacks(credentials: credentials))
	}
}

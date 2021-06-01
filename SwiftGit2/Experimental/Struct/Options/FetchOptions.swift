//
//  FetchOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class FetchOptions {
    let callbacks: RemoteCallbacks
    private var fetch_options = git_fetch_options()

    public init(callbacks: RemoteCallbacks = RemoteCallbacks()) {
        self.callbacks = callbacks

        let result = git_fetch_options_init(&fetch_options, UInt32(GIT_FETCH_OPTIONS_VERSION))
        assert(result == GIT_OK.rawValue)
    }

    public convenience init(auth: Auth) {
        self.init(callbacks: RemoteCallbacks(auth: auth))
    }
}

extension FetchOptions {
    func with_git_fetch_options<T>(_ body: (inout git_fetch_options) -> T) -> T {
        return callbacks.with_git_remote_callbacks { remote_callbacks in
            fetch_options.callbacks = remote_callbacks
            return body(&fetch_options)
        }
    }
}

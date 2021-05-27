//
//  PushOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 17.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class PushOptions {
    let callbacks: RemoteCallbacks
    private var push_options = git_push_options()
    
    public init(callbacks: RemoteCallbacks) {
        self.callbacks = callbacks
        
        let result = git_push_init_options(&push_options, UInt32(GIT_PUSH_OPTIONS_VERSION))
        assert(result == GIT_OK.rawValue)
    }
    
    public convenience init(auth: Auth = .auto) {
        self.init(callbacks: RemoteCallbacks(auth: auth))
    }
}

extension PushOptions {
    func with_git_push_options<T>(_ body: (inout git_push_options) -> T) -> T {
        return callbacks.with_git_remote_callbacks { remote_callbacks in
            push_options.callbacks = remote_callbacks
            return body(&push_options)
        }
    }
}


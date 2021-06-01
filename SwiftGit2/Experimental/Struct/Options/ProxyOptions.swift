//
//  ProxyOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 26.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class ProxyOptions {
    private var proxy_options = git_proxy_options()

    public init() {
        git_proxy_options_init(&proxy_options, UInt32(GIT_PROXY_OPTIONS_VERSION))
    }
}

internal extension ProxyOptions {
    func with_git_proxy_options<T>(_ body: (inout git_proxy_options) -> T) -> T {
        body(&proxy_options)
    }
}

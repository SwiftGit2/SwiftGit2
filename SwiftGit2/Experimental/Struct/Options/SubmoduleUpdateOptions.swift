//
//  SubmoduleUpdateOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 10.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class SubmoduleUpdateOptions {
    var options = git_submodule_update_options()
    private let fetch: FetchOptions

    public init() {
        fetch = FetchOptions()
        git_submodule_update_options_init(&options, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION))
    }

    public init(fetchOptions: FetchOptions) {
        fetch = fetchOptions
        git_submodule_update_options_init(&options, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION))
    }
}

extension SubmoduleUpdateOptions {
    func with_git_submodule_update_options<T>(_ body: (inout git_submodule_update_options) -> T) -> T {
        fetch.with_git_fetch_options { fetch_options in
            options.fetch_opts = fetch_options
            return body(&options)
        }
    }
}

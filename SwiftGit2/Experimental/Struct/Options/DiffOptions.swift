//
//  DiffOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class DiffOptions {
    var diff_options = git_diff_options()
    let pathspec: [String]

    public init(pathspec: [String] = []) {
        self.pathspec = pathspec
        
        let result = git_diff_options_init(&diff_options, UInt32(GIT_DIFF_OPTIONS_VERSION))
        assert(result == GIT_OK.rawValue)
    }
}

extension DiffOptions {
    func with_diff_options<T>(_ body: (inout git_diff_options) -> T) -> T {
        if pathspec.isEmpty {
            return body(&diff_options)
        } else {
            return pathspec.with_git_strarray { strarray in
                diff_options.pathspec = strarray
                return body(&diff_options)
            }
        }
    }
}

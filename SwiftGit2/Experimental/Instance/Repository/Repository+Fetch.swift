//
//  Repository+Fetch.swift
//  SwiftGit2-OSX
//
//  Created by loki on 28.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension Repository {
    func fetch(options: FetchOptions = FetchOptions()) -> Result<(), Error> {
        HEAD()
            .flatMap { $0.asBranch() }
            .flatMap { Duo($0,self).remote() }
            .flatMap { $0.fetch(options: options)}
    }
}


public extension Remote {
    func fetch(options: FetchOptions) -> Result<(), Error> {
        return git_try("git_remote_fetch") {
            options.with_git_fetch_options {
                git_remote_fetch(pointer, nil, &$0, nil)
            }
        }
    }
}

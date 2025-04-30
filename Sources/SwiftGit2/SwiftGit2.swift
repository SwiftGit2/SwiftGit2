//
//  SwiftGit2.swift
//
//
//  Created by Mathijs Bernson on 01/03/2024.
//

import Foundation
import Clibgit2

public func SwiftGit2Init() -> Result<Int, NSError> {
    let status = git_libgit2_init()
    if status < 0 {
        return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_init"))
    } else {
        return .success(Int(status))
    }
}

public func SwiftGit2Shutdown() -> Result<Int, NSError> {
    let status = git_libgit2_shutdown()
    if status < 0 {
        return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_shutdown"))
    } else {
        return .success(Int(status))
    }
}

public func Libgit2Version() -> String {
    var major: Int32 = 0
    var minor: Int32 = 0
    var patch: Int32 = 0
    git_libgit2_version(&major, &minor, &patch)

    let version: String = [major, minor, patch]
        .map(String.init)
        .joined(separator: ".")

    return version
}

//
//  RepositoryInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Repository: InstanceProtocol {
    public var pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_repository_free(pointer)
    }
}

public extension Repository {
    class func at(url: URL) -> Result<Repository, NSError> {
        var pointer: OpaquePointer?

        return _result({ Repository(pointer!) }, pointOfFailure: "git_repository_open") {
            url.withUnsafeFileSystemRepresentation {
                git_repository_open(&pointer, $0)
            }
        }
    }

    class func create(url: URL) -> Result<Repository, NSError> {
        var pointer: OpaquePointer?

        return _result({ Repository(pointer!) }, pointOfFailure: "git_repository_init") {
            url.withUnsafeFileSystemRepresentation {
                git_repository_init(&pointer, $0, 1)
            }
        }
    }
}

// index
public extension Repository {
    func reset(path: String) -> Result<Void, NSError> {
        let dir = path
        var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
        var paths = git_strarray(strings: &dirPointer, count: 1)

        return HEAD()
            .flatMap { self.instanciate($0.oid) as Result<Commit, NSError> }
            .flatMap { commit in
                _result((), pointOfFailure: "git_reset_default") {
                    git_reset_default(self.pointer, commit.pointer, &paths)
                }
            }
    }
}

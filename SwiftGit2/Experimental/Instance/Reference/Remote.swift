//
//  RemoteRepo.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation
import Essentials

public class Remote: InstanceProtocol {
    public let pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_remote_free(pointer)
    }
}

public extension Remote {
    /// The name of the remote repo
    var name        : String    { String(validatingUTF8: git_remote_name(pointer))! }
    var url         : String    { String(validatingUTF8: git_remote_url(pointer))! }
    var connected   : Bool      { git_remote_connected(pointer) == 1 }

    func connect(direction: Direction, auth: Auth) -> R<(String, Credentials)> {
        let callbacks = RemoteCallbacks(auth: auth)
        let proxyOptions = ProxyOptions()

        return git_try("git_remote_connect") {
            proxyOptions.with_git_proxy_options { options in
                callbacks.with_git_remote_callbacks { cb in
                    git_remote_connect(pointer, git_direction(UInt32(direction.rawValue)), &cb, &options, nil)
                }
            }
        }.map { (self.url, callbacks.recentCredentials) }
    }
}

public enum Direction: Int32 {
    case fetch = 0 // GIT_DIRECTION_FETCH
    case push = 1 // GIT_DIRECTION_PUSH
}

extension Remote: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Git2.Remote: \(name) - \(url)"
    }
}

public extension Repository {
    func rename(remote: String, to newName: String) -> R<[String]> {
        var problems = git_strarray()
        defer {
            git_strarray_free(&problems)
        }

        return git_try("git_remote_rename") {
            remote.withCString { name in
                newName.withCString { new_name in
                    git_remote_rename(&problems, self.pointer, name, new_name)
                }
            }
        }.map { problems.map { $0 } }
    }
}

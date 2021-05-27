//
//  RemoteRepo.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Remote : InstanceProtocol {
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
    var name: String { String(validatingUTF8: git_remote_name(pointer))! }
    var url : String { String(validatingUTF8: git_remote_url(pointer))! }
    
    

    
    func push(branchName: String, options: PushOptions ) -> Result<(), Error> {
        print("Trying to push ''\(branchName)'' to remote ''\(self.name)'' with URL:''\(self.url)''")
        
        return git_try("git_remote_push") {
            options.with_git_push_options { push_options in
                [branchName].with_git_strarray { strarray in
                    git_remote_push(self.pointer, &strarray, &push_options)
                }
            }
        }
    }

    func fetch(options: FetchOptions) -> Result<(), Error> {
        return git_try("git_remote_fetch") {
            options.with_git_fetch_options {
                git_remote_fetch(pointer, nil, &$0, nil)
            }
        }
    }
    
    var connected : Bool { git_remote_connected(pointer) == 1 }
    
    func connect(direction: Direction, auth: Auth) -> Result<Remote, Error>  {
        let callbacks = RemoteCallbacks(auth: auth)
        let proxyOptions = ProxyOptions()
        
        return git_try("git_remote_connect") {
            proxyOptions.with_git_proxy_options { options in
                callbacks.with_git_remote_callbacks { cb in
                    git_remote_connect(pointer, git_direction(UInt32(direction.rawValue)), &cb, &options, nil)
                }
            }
        }.map { self }
    }
}

public enum Direction : Int32 {
    case fetch = 0	// GIT_DIRECTION_FETCH
    case push = 1	// GIT_DIRECTION_PUSH
}

extension Remote : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Git2.Remote: \(self.name) - \(self.url)" 
    }
}

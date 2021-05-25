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
    private var remoteType: RemoteType
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
        self.remoteType = .Original
    }
    
    public required init(_ pointer: OpaquePointer, remoteType: RemoteType) {
        self.pointer = pointer
        self.remoteType = remoteType
    }
    
    deinit {
        git_remote_free(pointer)
    }
}

public extension Remote {	
    /// The name of the remote repo
    var name: String { String(validatingUTF8: git_remote_name(pointer))! }
    
    /// The URL of the remote repo
    ///
    /// This may be an SSH URL, which isn't representable using `NSURL`.
    
    //TODO:LAME HACK
    var URL: String {
        let url = String(validatingUTF8: git_remote_url(pointer))!
        
        switch remoteType {
        case .Original:
            return url
        case .ForceSSH:
            return urlGetSsh(url: url)
        case .ForceHttps:
            return urlGetHttp(url: url)
        }
    }
    
    // https://github.com/ukushu/PushTest.git
    // ssh://git@github.com:ukushu/PushTest.git
    private func urlGetHttp(url: String) -> String {
        var url = String(validatingUTF8: git_remote_url(pointer))!
        
        if url.contains("https://") {
            return url
        }
        
        //else this is ssh and need to make https
        
        if url.contains("@") {
            let tmp = url.split(separator: "@")
            if tmp.count == 2 { url = String(tmp[1]) }
        }
        
        url = url.replacingOccurrences(of: "ssh://", with: "")
            .replacingOccurrences(of: ":", with: "/")
        
        return "https://\(url)"
    }
    
    // https://github.com/ukushu/PushTest.git
    // ssh://git@github.com:ukushu/PushTest.git
    private func urlGetSsh(url: String) -> String {
        var newUrl = url
        
        if newUrl.contains("github") {
            if !newUrl.contains("ssh://") && newUrl.contains("git@") {
                newUrl = "ssh://\(url)"
            }
            else if newUrl.contains("ssh://") && !newUrl.contains("git@") {
                newUrl = url.replacingOccurrences(of: "ssh://", with: "ssh://git@")
            }
        }
        else{
            if !newUrl.contains("ssh://"){
                newUrl = "ssh://\(url)"
            }
        }
        
        return newUrl.replacingOccurrences(of: ":", with: "/")
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

//
//  RemoteCallbacks.swift
//  SwiftGit2-OSX
//
//  Created by loki on 25.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public typealias TransferProgressCB = (git_indexer_progress)->(Bool) // return false to cancel progree

public class RemoteCallbacks {
    let credentials: Credentials
    private var remote_callbacks = git_remote_callbacks()
    public var transferProgress: TransferProgressCB?
    
    public init(credentials: Credentials = .default) {
        self.credentials = credentials
        
        let result = git_remote_init_callbacks(&remote_callbacks, UInt32(GIT_REMOTE_CALLBACKS_VERSION))
        assert(result == GIT_OK.rawValue)
    }
    
    #if DEBUG
    deinit {
        print("RemoteCallbacks deinit")
    }
    #endif
}

extension RemoteCallbacks {
    func with_git_remote_callbacks<T>(_ body: (inout git_remote_callbacks) -> T) -> T {
        
        remote_callbacks.payload = self.toRetainedPointer()
        remote_callbacks.credentials = credentialsCallback
        remote_callbacks.transfer_progress = transferCallback
        
        defer {
            RemoteCallbacks.release(pointer: remote_callbacks.payload)
        }
        
        return body(&remote_callbacks)
    }
}


/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
private func credentialsCallback(
    cred: UnsafeMutablePointer<UnsafeMutablePointer<git_cred>?>?,
    url: UnsafePointer<CChar>?,
    username: UnsafePointer<CChar>?,
    _: UInt32,
    payload: UnsafeMutableRawPointer? ) -> Int32 {
    
    guard let payload = payload else { return -1 }
    
    let name = username.map(String.init(cString:))
    
    let result: Int32
    
    switch RemoteCallbacks.unretained(pointer: payload).credentials {
    case .default:
        result = git_credential_default_new(cred)
    case .sshAgent:
        result = git_credential_ssh_key_from_agent(cred, name!)
    case .plaintext(let username, let password):
        result = git_credential_userpass_plaintext_new(cred, username, password)
    case .sshMemory(let username, let publicKey, let privateKey, let passphrase):
        result = git_credential_ssh_key_memory_new(cred, username, publicKey, privateKey, passphrase)
    case .ssh(publicKey: let publicKey, privateKey: let privateKey, passphrase: let passphrase):
        result = git_credential_ssh_key_new(cred, name, publicKey, privateKey, passphrase)
    }
    
    return (result != GIT_OK.rawValue) ? -1 : 0
}

// Return a value less than zero to cancel process
private func transferCallback(stats: UnsafePointer<git_indexer_progress>?, payload: UnsafeMutableRawPointer? ) -> Int32 {
    guard let stats = stats?.pointee else { return -1 }
    guard let payload = payload else { return -1 }
    
    let callbacks = RemoteCallbacks.unretained(pointer: payload)
    
    // if progress callback didn't set just continue
    if let transferProgress = callbacks.transferProgress {
        if transferProgress(stats) == false {
            return -1 // if callback returns false return -1 to cancel transfer
        }
    }
    
    return 0
}

private extension RemoteCallbacks {
    static func unretained(pointer: UnsafeMutableRawPointer) -> RemoteCallbacks {
        return Unmanaged<Wrapper<RemoteCallbacks>>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue().value
    }
    
    func toRetainedPointer() -> UnsafeMutableRawPointer {
        return Unmanaged.passRetained(Wrapper(self)).toOpaque()
    }
    
    static func release(pointer: UnsafeMutableRawPointer) {
        Unmanaged<Wrapper<RemoteCallbacks>>.fromOpaque(UnsafeRawPointer(pointer)).release()
    }
}

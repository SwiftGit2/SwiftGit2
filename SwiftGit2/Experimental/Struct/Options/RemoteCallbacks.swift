//
//  RemoteCallbacks.swift
//  SwiftGit2-OSX
//
//  Created by loki on 25.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public typealias TransferProgressCB = (git_indexer_progress) -> (Bool) // return false to cancel progree
public typealias AuthCB = (_ url: String?, _ username: String?) -> (Credentials)

public enum Auth {
    case match(AuthCB)
    case auto
    case credentials(Credentials)
}

public class RemoteCallbacks: GitPayload {
    let auth: Auth
    private var remote_callbacks = git_remote_callbacks()
    public var transferProgress: TransferProgressCB?

    public init(auth: Auth = .auto) {
        self.auth = auth

        let result = git_remote_init_callbacks(&remote_callbacks, UInt32(GIT_REMOTE_CALLBACKS_VERSION))
        assert(result == GIT_OK.rawValue)
    }

    #if DEBUG
        deinit {
            // print("RemoteCallbacks deinit")
        }
    #endif
}

extension RemoteCallbacks {
    func with_git_remote_callbacks<T>(_ body: (inout git_remote_callbacks) -> T) -> T {
        remote_callbacks.payload = toRetainedPointer()

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
    payload: UnsafeMutableRawPointer?
) -> Int32 {
    guard let payload = payload else { return -1 }

    let url = url.map(String.init(cString:))
    let name = username.map(String.init(cString:))

    let result: Int32

    switch RemoteCallbacks.unretained(pointer: payload).auth.credentials(url: url, name: name) {
    case .none:
        return -1
    case .default:
        result = git_credential_default_new(cred)
    case .sshAgent:
        result = git_credential_ssh_key_from_agent(cred, name!)
    case let .plaintext(username, password):
        result = git_credential_userpass_plaintext_new(cred, username, password)
    case let .sshMemory(username, publicKey, privateKey, passphrase):
        result = git_credential_ssh_key_memory_new(cred, username, publicKey, privateKey, passphrase)
    case let .ssh(publicKey: publicKey, privateKey: privateKey, passphrase: passphrase):
        result = git_credential_ssh_key_new(cred, name, publicKey, privateKey, passphrase)
    }

    return (result != GIT_OK.rawValue) ? -1 : 0
}

// Return a value less than zero to cancel process
private func transferCallback(stats: UnsafePointer<git_indexer_progress>?, payload: UnsafeMutableRawPointer?) -> Int32 {
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

public extension Auth {
    func credentials(url: String?, name: String?) -> Credentials {
        switch self {
        case .auto:
            if url?.starts(with: "http") ?? false {
                return .default
            }
            return Credentials.sshDefault
        case let .match(callback):
            return callback(url, name)
        case let .credentials(c):
            return c
        }
    }
}

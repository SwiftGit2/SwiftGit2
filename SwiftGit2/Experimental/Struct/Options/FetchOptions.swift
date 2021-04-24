//
//  FetchOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public typealias TransferProgressCB = (git_indexer_progress)->(Bool) // return false to cancel progree

public struct FetchOptions {
	var fetch_options = git_fetch_options()
	let credentials: Credentials_OLD
	
	var transferProgress : TransferProgressCB?
	
	public init(credentials: Credentials_OLD = .default, transferProgress: TransferProgressCB? = nil) {
		self.credentials = credentials
		self.transferProgress = transferProgress

		let result = git_fetch_options_init(&fetch_options, UInt32(GIT_FETCH_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		fetch_options.callbacks.payload = self.toPointer()
		fetch_options.callbacks.credentials = credentialsCallback
		fetch_options.callbacks.transfer_progress = transferCallback
	}
	
	internal static func fromPointer(_ pointer: UnsafeMutableRawPointer) -> FetchOptions {
		return Unmanaged<Wrapper<FetchOptions>>.fromOpaque(UnsafeRawPointer(pointer)).takeRetainedValue().value
	}

	internal func toPointer() -> UnsafeMutableRawPointer {
		return Unmanaged.passRetained(Wrapper(self)).toOpaque()
	}
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
internal func credentialsCallback(
	cred: UnsafeMutablePointer<UnsafeMutablePointer<git_cred>?>?,
	url: UnsafePointer<CChar>?,
	username: UnsafePointer<CChar>?,
	_: UInt32,
	payload: UnsafeMutableRawPointer? ) -> Int32 {
	
	guard let payload = payload else { return -1 }
		
	let name = username.map(String.init(cString:))
	
	let result: Int32
	
	switch FetchOptions.fromPointer( payload).credentials {
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

internal func transferCallback(stats: UnsafePointer<git_indexer_progress>?, payload: UnsafeMutableRawPointer? ) -> Int32 {
	guard let stats = stats else { return -1 }
	guard let payload = payload else { return -1 }
	
	// if progress callback didn't set just continue
	guard let transferProgress = FetchOptions.fromPointer(payload).transferProgress else { return 0 }
	
	// if callback returns false return -1 to cancel transfer
	return transferProgress(stats.pointee) ? 0 : -1
}

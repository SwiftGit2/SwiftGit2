//
//  FetchOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class FetchOptions {
	var fetch_options = git_fetch_options()
	let credentials: Credentials_OLD
	
	public init(credentials: Credentials_OLD) {
		self.credentials = credentials
		setUp()
	}
	
	public init() {
		self.credentials = Credentials_OLD.default
		setUp()
	}
	
	private func setUp() {
		let result = git_fetch_options_init(&fetch_options, UInt32(GIT_FETCH_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		// workaround to pass self pointer as Payload
		let blockPointer = UnsafeMutablePointer<FetchOptions>.allocate(capacity: 1)
		blockPointer.initialize(to: self)
		fetch_options.callbacks.payload = UnsafeMutableRawPointer(blockPointer)
		fetch_options.callbacks.credentials = credentialsCallback
	}
	
	internal static func from(pointer: UnsafeMutableRawPointer) -> FetchOptions {
		return Unmanaged<FetchOptions>.fromOpaque(UnsafeRawPointer(pointer)).takeRetainedValue()
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
	
	guard let payload = payload else {  return -1 }
		
	let fetchOptions = FetchOptions.from(pointer: payload)
	let name = username.map(String.init(cString:))
	
	let result: Int32
	
	switch fetchOptions.credentials {
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

//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import Clibgit2

private class Wrapper<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

public enum Credentials_OLD {
	case `default`
	case sshAgent
	case plaintext(username: String, password: String)
	case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)
	case ssh(publicKey: String, privateKey: String, passphrase: String)

	internal static func fromPointer(_ pointer: UnsafeMutableRawPointer) -> Credentials_OLD {
		return Unmanaged<Wrapper<Credentials_OLD>>.fromOpaque(UnsafeRawPointer(pointer)).takeRetainedValue().value
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

	let result: Int32

	// Find username_from_url
	let name = username.map(String.init(cString:))

	switch Credentials_OLD.fromPointer(payload!) {
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

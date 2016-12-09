//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import Foundation
import Result

private class Wrapper<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

public enum Credentials {
	case Default()
	case Plaintext(username: String, password: String)
	case SSHMemory(username: String, publicKey: String, privateKey: String, passphrase: String)

	internal static func fromPointer(pointer: UnsafeMutablePointer<()>) -> Credentials {
		return Unmanaged<Wrapper<Credentials>>.fromOpaque(COpaquePointer(pointer)).takeRetainedValue().value
	}

	internal func toPointer() -> UnsafeMutablePointer<()> {
		return UnsafeMutablePointer(Unmanaged.passRetained(Wrapper(self)).toOpaque())
	}
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds, -1 error)
internal func credentialsCallback(cred: UnsafeMutablePointer<UnsafeMutablePointer<git_cred>>, _: UnsafePointer<Int8>, _: UnsafePointer<Int8>, _: UInt32,
	payload: UnsafeMutablePointer<()>) -> Int32 {
	let result: Int32

	switch Credentials.fromPointer(payload) {
	case .Default():
		result = git_cred_default_new(cred)
	case .Plaintext(let username, let password):
		result = git_cred_userpass_plaintext_new(cred, username, password)
	case .SSHMemory(let username, let publicKey, let privateKey, let passphrase):
		result = git_cred_ssh_key_memory_new(cred, username, publicKey, privateKey, passphrase)
	}

	return (result != GIT_OK.rawValue) ? -1 : 0
}

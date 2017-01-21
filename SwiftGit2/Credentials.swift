//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import libgit2

private class Wrapper<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

/// Convert libgit2 string to Swift string
///
/// - parameter cStr: C string pointer
///
/// - returns: Swift string
func git_string_converter(_ cStr: UnsafePointer<CChar>) -> String {
	return String(cString: cStr)
}

public enum Credentials {
	case Default()
	case Agent()
	case Plaintext(password: String)
	case SSHMemory(publicKey: String, privateKey: String, passphrase: String)

	internal static func fromPointer(_ pointer: UnsafeMutableRawPointer) -> Credentials {
		return Unmanaged<Wrapper<Credentials>>.fromOpaque(UnsafeRawPointer(pointer)).takeRetainedValue().value
	}

	internal func toPointer() -> UnsafeMutableRawPointer {
		return Unmanaged.passRetained(Wrapper(self)).toOpaque()
	}
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
internal func credentialsCallback(cred: UnsafeMutablePointer<UnsafeMutablePointer<git_cred>?>?,
                                  url: UnsafePointer<CChar>?,
                                  username: UnsafePointer<Int8>?,
                                  _: UInt32, payload: UnsafeMutableRawPointer?) -> Int32 {
	let result: Int32

	// Find url
//	let sUrl: String?
//	if url == nil {
//		sUrl = nil
//	} else {
//		sUrl = git_string_converter(url!)
//	}

	// Find username_from_url
	let userName: String?
	if username == nil {
		userName = nil
	} else {
		userName = git_string_converter(username!)
	}

	switch Credentials.fromPointer(payload!) {
	case .Default():
		result = git_cred_default_new(cred)
	case .Agent():
		result = git_cred_ssh_key_from_agent(cred, userName)
	case .Plaintext(let password):
		result = git_cred_userpass_plaintext_new(cred, userName, password)
	case .SSHMemory(let publicKey, let privateKey, let passphrase):
		result = git_cred_ssh_key_memory_new(cred, userName, publicKey, privateKey, passphrase)
	}

	return (result != GIT_OK.rawValue) ? -1 : 0
}

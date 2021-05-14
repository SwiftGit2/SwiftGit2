//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import Clibgit2

internal class Wrapper<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

public enum Credentials {
	case `default`
	case sshAgent
	case plaintext(username: String, password: String)
	case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)
	case ssh(publicKey: String, privateKey: String, passphrase: String)

	internal static func fromPointer(_ pointer: UnsafeMutableRawPointer) -> Credentials {
		return Unmanaged<Wrapper<Credentials>>.fromOpaque(UnsafeRawPointer(pointer)).takeRetainedValue().value
	}

	internal func toPointer() -> UnsafeMutableRawPointer {
		return Unmanaged.passRetained(Wrapper(self)).toOpaque()
	}
}


//
//  GitPayload.swift
//  SwiftGit2-OSX
//
//  Created by loki on 17.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation

internal protocol GitPayload { }

internal class Wrapper<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

internal extension GitPayload {
	static func unretained(pointer: UnsafeMutableRawPointer) -> Self {
		return Unmanaged<Wrapper<Self>>.fromOpaque(UnsafeRawPointer(pointer)).takeUnretainedValue().value
	}
	
	func toRetainedPointer() -> UnsafeMutableRawPointer {
		return Unmanaged.passRetained(Wrapper(self)).toOpaque()
	}
	
	static func release(pointer: UnsafeMutableRawPointer) {
		Unmanaged<Wrapper<Self>>.fromOpaque(UnsafeRawPointer(pointer)).release()
	}
}

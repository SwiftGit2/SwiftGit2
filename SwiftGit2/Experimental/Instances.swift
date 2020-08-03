//
//  Instances.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public protocol InstanceType {
	static func free(pointer: OpaquePointer) 
}

public final class Instance<Type> where Type : InstanceType {
	public let pointer: OpaquePointer
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	deinit {
		Type.free(pointer: pointer)
	}
}




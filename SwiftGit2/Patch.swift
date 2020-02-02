//
//  Patch.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Patch {
	let pointer: OpaquePointer
	
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_patch_free(pointer)
	}
}

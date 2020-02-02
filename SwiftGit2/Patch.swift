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
	
	func asBuffer() -> Result<OpaquePointer, NSError> {
		let buff = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
		
		return _result(pointer, pointOfFailure: "git_patch_to_buf") {
			git_patch_to_buf(buff, pointer)
		}
	}
	
	func size() -> Int {
		return git_patch_size(pointer, 0, 0, 0)
	}
}

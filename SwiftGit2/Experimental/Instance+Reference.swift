//
//  Instance+Reference.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

extension Reference : InstanceType {
	public func free(pointer: OpaquePointer) {
		git_reference_free(pointer)
	}
}


public extension Instance where Type == Reference {
	var isBranch : Bool { git_reference_is_branch(pointer) 	!= 0 }
	var isRemote : Bool { git_reference_is_remote(pointer) 	!= 0 }
	var isTag    : Bool { git_reference_is_tag(pointer) 	!= 0 }
	
//	func asBranch() -> Instance<Branch>? {
//		if isBranch || isRemote {
//			return self as? Instance<Branch>
//		}
//		return nil
//	}
}

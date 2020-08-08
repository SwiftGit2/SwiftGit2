//
//  Instance+Index.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

extension Index : InstanceType {
	public static func free(pointer: OpaquePointer) {
		git_index_free(pointer)
	}
}



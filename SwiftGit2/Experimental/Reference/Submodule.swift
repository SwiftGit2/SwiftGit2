//
//  Submodule.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 06.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2



public class Submodule: InstanceProtocol {
	public let pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_submodule_free(pointer)
	}
}

public extension Submodule {
	var name : String { return String(cString: git_submodule_name(self.pointer)) }
	var path : String { return String(cString: git_submodule_path(self.pointer)) }
	var url  : String { return String(cString: git_submodule_url(self.pointer)) }
}


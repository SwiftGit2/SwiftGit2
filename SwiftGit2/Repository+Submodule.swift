//
//  Repository+Submodule.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 14.01.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation

public extension Repository {
	func submodules() {
		git_submodule_foreach(self.pointer, )
	}
}


final class Submodule {
	
}

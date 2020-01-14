//
//  Repository+Submodule.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 14.01.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension Repository {
	func submodules() -> Result<[String], NSError> {
		var cb = SubmodeleEachCallback()
		let result = git_submodule_foreach(self.pointer, cb.each_submodule_cb, &cb)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_index_to_workdir"))
		}
		
		return .success(cb.items)
	}
}


class SubmodeleEachCallback {
	var items = [String]()

	let each_submodule_cb : git_submodule_cb = { submodule, name, callbacks in
		guard let name = name else { fatalError() }
		
		callbacks.unsafelyUnwrapped
			.bindMemory(to: SubmodeleEachCallback.self, capacity: 1)
			.pointee
			.next(name: String(cString: name))
		
		return 0
	}
	
	func next(name: String) {
		items.append(name)
	}
}

final class Submodule {
	
}

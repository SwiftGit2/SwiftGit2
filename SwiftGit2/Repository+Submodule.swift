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
	func submodules() -> Result<[Submodule], NSError> {
		var cb = SubmodeleEachCallback(repoPointer: self.pointer)
		let result = git_submodule_foreach(self.pointer, cb.each_submodule_cb, &cb)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_index_to_workdir"))
		}
		
		return .success(cb.items)
	}
}


class SubmodeleEachCallback {
	var items = [Submodule]()
	let repoPointer : OpaquePointer
	
	init(repoPointer: OpaquePointer) {
		self.repoPointer = repoPointer
	}

	let each_submodule_cb : git_submodule_cb = { submodule, name, callbacks in
		guard let name = name else { fatalError() }
		
		callbacks.unsafelyUnwrapped
			.bindMemory(to: SubmodeleEachCallback.self, capacity: 1)
			.pointee
			.next(sm: submodule, name: String(cString: name))
		
		return 0
	}
	
	func next(sm: OpaquePointer?, name: String) {
		//guard let pointer = sm else { fatalError("submodule nil pointer") }
		
		var submodulePointer: OpaquePointer? = nil
		
		git_submodule_lookup(&submodulePointer, repoPointer, name)
		
		if let sm = submodulePointer {
			items.append(Submodule(pointer: sm))
		}
	}
}

public final class Submodule {
	public let  pointer		: OpaquePointer
	
	public var name : String { return String(cString: git_submodule_name(pointer)) }
	public var path : String { return String(cString: git_submodule_path(pointer)) }
	public var url  : String { return String(cString: git_submodule_url(pointer)) }
	
	init(pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_submodule_free(pointer)
	}
	
	public func open() -> Result<Repository, NSError>  {
		var repoPointer: OpaquePointer? = nil
		git_submodule_open(&repoPointer, pointer)
		
		if let repoPointer = repoPointer {
			return .success(Repository(repoPointer))
		} else {
			return Result.failure(NSError(gitError: 0, pointOfFailure: "git_submodule_open"))
		}
	}
}

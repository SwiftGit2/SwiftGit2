//
//  Repository+Submodule.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 14.01.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension RepositoryOLD {
	func submodules() -> Result<[Submodule_OLD], NSError> {
		var cb = SubmodeleEachCallback(repoPointer: self.pointer)
		let result = git_submodule_foreach(self.pointer, cb.each_submodule_cb, &cb)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_index_to_workdir"))
		}
		
		return .success(cb.items)
	}
}


class SubmodeleEachCallback {
	var items = [Submodule_OLD]()
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
			items.append(Submodule_OLD(pointer: sm))
		}
	}
}

public final class Submodule_OLD {
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
	
	public func open() -> Result<RepositoryOLD, NSError>  {
		var repoPointer: OpaquePointer? = nil
		git_submodule_open(&repoPointer, pointer)
		
		if let repoPointer = repoPointer {
			return .success(RepositoryOLD(repoPointer))
		} else {
			return Result.failure(NSError(gitError: 0, pointOfFailure: "git_submodule_open"))
		}
	}
}

public extension Thread {
    
    var dbgName: String {
		if #available(OSXApplicationExtension 10.10, *) {
			if let currentOperationQueue = OperationQueue.current?.name {
				
				if currentOperationQueue.contains("OperationQueue") {
					return currentOperationQueue
				} else {
					return "OperationQueue: \(currentOperationQueue)"
				}
				
			} else if let underlyingDispatchQueue = OperationQueue.current?.underlyingQueue?.label {
				
				if underlyingDispatchQueue.contains("DispatchQueue") {
					return underlyingDispatchQueue
				} else {
					return "DispatchQueue: \(underlyingDispatchQueue)"
				}
				
			} else {
				let name = __dispatch_queue_get_label(nil)
				return String(cString: name, encoding: .utf8) ?? Thread.current.description
			}
		} else {
			return ""
		}
    }
}

func log(title: String, msg: String) {
	print("\(time) [\(title)] (\(Thread.current.dbgName)) \(msg)")
}


fileprivate var time : String { return debugDateFormatter.string(from: Date()) }

private let debugDateFormatter: DateFormatter = { () -> DateFormatter in
	let dateFormatter = DateFormatter()
	dateFormatter.dateFormat = "HH:mm:ss.SSS"
	return dateFormatter
}()

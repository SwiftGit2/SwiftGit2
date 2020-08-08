//
//  IndexInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public final class Index : InstanceProtocol {
	public var pointer: OpaquePointer
	
	required public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_index_free(pointer)
	}
}

public extension Repository {
	func index() -> Result<Index, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Index(pointer!) }, pointOfFailure: "git_repository_index") {
			git_repository_index(&pointer, pointer)
		}
	}
}

public extension Index {
	var entrycount : Int { git_index_entrycount(pointer) }

	func entries() -> Result<[IndexOld.Entry], NSError> {
		var entries = [IndexOld.Entry]()
		for i in 0..<entrycount {
			if let entry = git_index_get_byindex(pointer, i) {
				entries.append(IndexOld.Entry(entry: entry.pointee))
			}
		}
		return .success(entries)
	}
	
	func add(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		
		return _result((), pointOfFailure: "git_index_add_all") {
			git_index_add_all(pointer, &paths, 0, nil, nil)
		}
		.flatMap { self.write() }
	}
	
	func remove(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		
		return _result((), pointOfFailure: "git_index_add_all") {
			git_index_remove_all(pointer, &paths, nil, nil)
		}
		.flatMap { self.write() }
	}
	
	func clear() -> Result<(), NSError> {
		return _result((), pointOfFailure: "git_index_clear") {
			git_index_clear(pointer)
		}
	}
	
	private func write() -> Result<(),NSError> {
		return _result((), pointOfFailure: "git_index_write") {
			git_index_write(pointer)
		}
	}
}

//
//  Repository+Status.swift
//  SwiftGit2-OSX
//
//  Created by loki on 21.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public final class StatusIterator {
	public var pointer: OpaquePointer?
	
	public init(_ pointer: OpaquePointer?) {
		self.pointer = pointer
	}
	
	deinit {
		if let pointer = pointer {
			git_status_list_free(pointer)
		}
	}
}

extension StatusIterator : RandomAccessCollection {
	public typealias Element 		= StatusEntry
	public typealias Index 			= Int
	public typealias SubSequence 	= StatusIterator
	public typealias Indices 		= DefaultIndices<StatusIterator>

	public subscript(position: Int) -> StatusEntry {
		_read {
			let s = git_status_byindex(pointer!, position)
			yield StatusEntry(from: s!.pointee)
		}
	}
	
	public var startIndex	: Int { 0 }
	public var endIndex		: Int {
		if let pointer = pointer {
			return git_status_list_entrycount(pointer)
		}
		
		return 0
	}
	
	public func index(before i: Int) -> Int { return i - 1 }
	public func index(after i: Int)  -> Int { return i + 1 }
}

public extension Repository {
	
	// CheckThatRepoIsEmpty
	func repoIsBare() -> Bool {
		let a = git_repository_is_bare(self.pointer)
		
		return a == 1 ? true : false
	}
	
	
	func status(options: StatusOptions = StatusOptions(), filter: String? = nil) -> Result<StatusIterator, Error> {
		var pointer: OpaquePointer? = nil
		var git_options = options.git_options

		if repoIsBare() {
			return .success( StatusIterator(nil) )
		}

		//TODO: Ugly hack. Need to move to StatusOptions() but it's a little bit difficult
		if let filter = filter {
			if filter.count > 0 {
				var dirPointer = UnsafeMutablePointer<Int8>(mutating: (filter as NSString).utf8String)
				git_options.pathspec = git_strarray(strings: &dirPointer, count: 1)
			}
		}

		return _result( { StatusIterator(pointer!) }, pointOfFailure: "git_status_list_new") {
			git_status_list_new(&pointer, self.pointer, &git_options)
		}
	}
}

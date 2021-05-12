//
//  Repository+Index.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension RepositoryOLD  {
	func index() -> Result<IndexOld, Error> {
		var index_pointer: OpaquePointer? = nil
		
		return _result( { IndexOld(pointer: index_pointer!) }, pointOfFailure: "git_repository_index") {
			git_repository_index(&index_pointer, pointer)
		}
	}
}

public final class IndexOld {
	public let pointer: OpaquePointer
	
	public var entrycount : Int { git_index_entrycount(pointer) }
	
	public init(pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_index_free(pointer)
	}
	
	public func entries() -> Result<[IndexOld.Entry], Error> {
		var entries = [IndexOld.Entry]()
		for i in 0..<entrycount {
			if let entry = git_index_get_byindex(pointer, i) {
				entries.append(IndexOld.Entry(entry: entry.pointee))
			}
		}
		return .success(entries)
	}
	
	public func add(path: String) -> Result<(), Error> {
		var paths = git_strarray(string: path)
		
		return _result((), pointOfFailure: "git_index_add_all") {
			git_index_add_all(pointer, &paths, 0, nil, nil)
		}
		.flatMap { self.write() }
	}
	
	public func remove(path: String) -> Result<(), Error> {
		var paths = git_strarray(string: path)
		
		return _result((), pointOfFailure: "git_index_add_all") {
			git_index_remove_all(pointer, &paths, nil, nil)
		}
		.flatMap { self.write() }
	}
	
	public func clear() -> Result<(), Error> {
		return _result((), pointOfFailure: "git_index_clear") {
			git_index_clear(pointer)
		}
	}
	
	func write() -> Result<(),Error> {
		return _result((), pointOfFailure: "git_index_write") {
			git_index_write(pointer)
		}
	}
}

public extension IndexOld {
	struct Time {
		let seconds : Int32
		let nanoseconds : UInt32
		
		init(_ time: git_index_time) {
			seconds 	= time.seconds
			nanoseconds = time.nanoseconds
		}
	}
	
	struct Entry {
		public let ctime		: Time
		public let mtime		: Time
		public let dev			: UInt32
		public let ino			: UInt32
		public let mode 		: UInt32
		public let uid			: UInt32
		public let gid			: UInt32
		public let fileSize 	: UInt32
		public let oid			: OID
		
		public let flags			: Flags
		public let flagsExtended 	: FlagsExtended
		
		public let path : String
		
		public let stage 		: Int32
		
		init(entry: git_index_entry) {
			
			ctime		= Time(entry.ctime)
			mtime		= Time(entry.mtime)
			dev 		= entry.dev
			ino			= entry.ino
			mode		= entry.mode
			uid 		= entry.uid
			gid 		= entry.gid
			fileSize 	= entry.file_size
			oid 		= OID(entry.id)
			
			flags 			= Flags(rawValue: UInt32(entry.flags))
			flagsExtended 	= FlagsExtended(rawValue: UInt32(entry.flags_extended))
			
			path 		= String(cString: entry.path)
			
			var mutableEntry = entry
			stage = git_index_entry_stage(&mutableEntry)
		}
	}
}

public extension IndexOld.Entry {
	struct Flags: OptionSet {

		public let rawValue: UInt32
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		
		public static let extended	= Flags(rawValue: GIT_INDEX_ENTRY_EXTENDED.rawValue)
		public static let valid		= Flags(rawValue: GIT_INDEX_ENTRY_VALID.rawValue)
	}
	
	struct FlagsExtended: OptionSet {
		public let rawValue: UInt32
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		
		public static let intendedToAdd		= Flags(rawValue: GIT_INDEX_ENTRY_INTENT_TO_ADD.rawValue)
		public static let skipWorkTree		= Flags(rawValue: GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue)
		public static let extendedFlags		= Flags(rawValue: GIT_INDEX_ENTRY_EXTENDED_FLAGS.rawValue)
		public static let update			= Flags(rawValue: GIT_INDEX_ENTRY_UPTODATE.rawValue)
	}
}

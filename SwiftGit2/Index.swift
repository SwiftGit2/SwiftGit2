//
//  Repository+Index.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

extension Repository  {
	func index() -> Result<Index, NSError> {
		var index_pointer: OpaquePointer? = nil
		
		let result = git_repository_index(&index_pointer, pointer)
		
		if result == GIT_OK.rawValue {
			return .success(Index(pointer: index_pointer!))
		} else {
			return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
		}
	}
}

class Index {
	public let pointer: OpaquePointer
	
	var entrycount : Int { git_index_entrycount(pointer) }
	
	init(pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_index_free(pointer)
	}
	
	func entries() -> Result<[Index.Entry], NSError> {
		var entries = [Index.Entry]()
		for i in 0..<entrycount {
			if let entry = git_index_get_byindex(pointer, i) {
				entries.append(Index.Entry(entry: entry.pointee))
			}
		}
		return .success(entries)
	}
}

extension Index {
	struct Time {
		let seconds : Int32
		let nanoseconds : UInt32
		
		init(_ time: git_index_time) {
			seconds 	= time.seconds
			nanoseconds = time.nanoseconds
		}
	}
	
	struct Entry {
		let ctime		: Time
		let mtime		: Time
		let dev			: UInt32
		let ino			: UInt32
		let mode 		: UInt32
		let uid 		: UInt32
		let gid 		: UInt32
		let fileSize 	: UInt32
		let oid			: OID
		
		let flags			: Flags
		let flagsExtended 	: FlagsExtended
		
		let path : String
		
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
		}
	}
}

extension Index.Entry {
	public struct Flags: OptionSet {

		public let rawValue: UInt32
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		
		public static let extended	= Flags(rawValue: GIT_INDEX_ENTRY_EXTENDED.rawValue)
		public static let valid		= Flags(rawValue: GIT_INDEX_ENTRY_VALID.rawValue)
	}
	
	public struct FlagsExtended: OptionSet {
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

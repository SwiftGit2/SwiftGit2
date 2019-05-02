//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

import Foundation
import libgit2

//git_diff_find_options

public struct StatusEntry {
	public var status: Diff.Status
	public var headToIndex: Diff.Delta?
	public var indexToWorkDir: Diff.Delta?

	public init(from statusEntry: git_status_entry) {
		self.status = Diff.Status(rawValue: statusEntry.status.rawValue)

		if let htoi = statusEntry.head_to_index {
			self.headToIndex = Diff.Delta(htoi.pointee)
		}

		if let itow = statusEntry.index_to_workdir {
			self.indexToWorkDir = Diff.Delta(itow.pointee)
		}
	}
}

public struct Diff {

	/// The set of deltas.
	public var deltas = [Delta]()

	public struct Delta {
		public static let type = GIT_OBJ_REF_DELTA

		public var status: Status
		public var flags: Flags
		public var oldFile: File?
		public var newFile: File?

		public init(_ delta: git_diff_delta) {
			self.status = Status(rawValue: UInt32(git_diff_status_char(delta.status)))
			self.flags = Flags(rawValue: delta.flags)
			self.oldFile = File(delta.old_file)
			self.newFile = File(delta.new_file)
		}
	}

	public struct File {
		public var oid: OID
		public var path: String
		public var size: Int64
		public var flags: Flags

		public init(_ diffFile: git_diff_file) {
			self.oid = OID(diffFile.id)
			let path = diffFile.path
			self.path = path.map(String.init(cString:))!
			self.size = diffFile.size
			self.flags = Flags(rawValue: diffFile.flags)
		}
	}
	
	public struct Hunk {
		public let oldStart : Int
		public let oldLines : Int
		public let newStart : Int
		public let newLines : Int
		public let header   : String
		
		public init(_ hunk: git_diff_hunk) {
			oldStart = Int(hunk.old_start)
			oldLines = Int(hunk.old_lines)
			newStart = Int(hunk.new_start)
			newLines = Int(hunk.new_lines)

			let bytes = Mirror(reflecting: hunk.header)
				.children
				.map { UInt8($0.value as! Int8) }
				.filter { $0 > 0 }
			
			header = String(bytes: bytes, encoding: String.Encoding.utf8)!
		}
	}

	public struct Status: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let current                = Status(rawValue: GIT_STATUS_CURRENT.rawValue)
		public static let indexNew               = Status(rawValue: GIT_STATUS_INDEX_NEW.rawValue)
		public static let indexModified          = Status(rawValue: GIT_STATUS_INDEX_MODIFIED.rawValue)
		public static let indexDeleted           = Status(rawValue: GIT_STATUS_INDEX_DELETED.rawValue)
		public static let indexRenamed           = Status(rawValue: GIT_STATUS_INDEX_RENAMED.rawValue)
		public static let indexTypeChange        = Status(rawValue: GIT_STATUS_INDEX_TYPECHANGE.rawValue)
		public static let workTreeNew            = Status(rawValue: GIT_STATUS_WT_NEW.rawValue)
		public static let workTreeModified       = Status(rawValue: GIT_STATUS_WT_MODIFIED.rawValue)
		public static let workTreeDeleted        = Status(rawValue: GIT_STATUS_WT_DELETED.rawValue)
		public static let workTreeTypeChange     = Status(rawValue: GIT_STATUS_WT_TYPECHANGE.rawValue)
		public static let workTreeRenamed        = Status(rawValue: GIT_STATUS_WT_RENAMED.rawValue)
		public static let workTreeUnreadable     = Status(rawValue: GIT_STATUS_WT_UNREADABLE.rawValue)
		public static let ignored                = Status(rawValue: GIT_STATUS_IGNORED.rawValue)
		public static let conflicted             = Status(rawValue: GIT_STATUS_CONFLICTED.rawValue)
	}

	public struct Flags: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let binary     = Flags(rawValue: GIT_DIFF_FLAG_BINARY.rawValue)
		public static let notBinary  = Flags(rawValue: GIT_DIFF_FLAG_NOT_BINARY.rawValue)
		public static let validId    = Flags(rawValue: GIT_DIFF_FLAG_VALID_ID.rawValue)
		public static let exists     = Flags(rawValue: GIT_DIFF_FLAG_EXISTS.rawValue)
	}
	
	public struct FindOptions: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32
		
		public static let byConfig						= FindOptions(rawValue: GIT_DIFF_FIND_BY_CONFIG.rawValue)
		public static let renames						= FindOptions(rawValue: GIT_DIFF_FIND_RENAMES.rawValue)
		public static let renamesFromRewrites			= FindOptions(rawValue: GIT_DIFF_FIND_RENAMES_FROM_REWRITES.rawValue)
		public static let copies						= FindOptions(rawValue: GIT_DIFF_FIND_COPIES.rawValue)
		public static let copiesFromUnmodified			= FindOptions(rawValue: GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED.rawValue)
		public static let rewrites						= FindOptions(rawValue: GIT_DIFF_FIND_REWRITES.rawValue)
		public static let breakRewrites					= FindOptions(rawValue: GIT_DIFF_BREAK_REWRITES.rawValue)
		public static let findAndBreakRewrites			= FindOptions(rawValue: GIT_DIFF_FIND_AND_BREAK_REWRITES.rawValue)
		public static let forUntracked					= FindOptions(rawValue: GIT_DIFF_FIND_FOR_UNTRACKED.rawValue)
		public static let all							= FindOptions(rawValue: GIT_DIFF_FIND_ALL.rawValue)
		
		public static let ignoreLeadingWhitespace		= FindOptions(rawValue: GIT_DIFF_FIND_IGNORE_LEADING_WHITESPACE.rawValue)
		public static let ignoreWhitespace				= FindOptions(rawValue: GIT_DIFF_FIND_IGNORE_WHITESPACE.rawValue)
		public static let dontIgnoreWhitespace			= FindOptions(rawValue: GIT_DIFF_FIND_DONT_IGNORE_WHITESPACE.rawValue)
		public static let exactMatchOnly				= FindOptions(rawValue: GIT_DIFF_FIND_EXACT_MATCH_ONLY.rawValue)
		public static let breakRewritesForRenamesOnly	= FindOptions(rawValue: GIT_DIFF_BREAK_REWRITES_FOR_RENAMES_ONLY.rawValue)
		public static let removeUnmodified				= FindOptions(rawValue: GIT_DIFF_FIND_REMOVE_UNMODIFIED.rawValue)
	}
	
	let pointer: OpaquePointer
	
	mutating public func findSimilar(options: FindOptions) {
		var opt = git_diff_find_options(version: 1, flags: options.rawValue, rename_threshold: 50, rename_from_rewrite_threshold: 50, copy_threshold: 50, break_rewrite_threshold: 60, rename_limit: 200, metric: nil)
		git_diff_find_similar(pointer, &opt)
		
		refreshDeltas()
	}
	
	private class DiffEachCallbacks {
		var fileBlock: ((Delta, Float32)->())?
		var hunkBlock: ((Delta, Hunk)->())?
	}
	
	public func forEach(file: ((Delta,Float32)->())?, hunk: ((Delta,Hunk)->())?) -> Result<Void,NSError> {
		let each_file_cb : git_diff_file_cb = { delta, progress, callbacks in
			let callbacks = callbacks.unsafelyUnwrapped.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			
			callbacks.pointee
				.fileBlock?(Delta(delta.unsafelyUnwrapped.pointee), progress)
			
			return 0
		}
		
		let git_diff_binary_cb : git_diff_binary_cb = { delta, binary, callbacks in
			
			return 0
		}
		
		let each_hunk_cb : git_diff_hunk_cb = { delta, hunk, callbacks in
			let callbacks = callbacks.unsafelyUnwrapped.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			
			callbacks.pointee
				.hunkBlock?(Delta(delta.unsafelyUnwrapped.pointee), Hunk(hunk.unsafelyUnwrapped.pointee))

			return 0
		}
		
		let each_line_cb : git_diff_line_cb = { delta, hunk, line, callbacks in
			return 0
		}
		
		var callbacks = DiffEachCallbacks()
		callbacks.fileBlock = file
		callbacks.hunkBlock = hunk
		
		let result = git_diff_foreach(pointer, each_file_cb, git_diff_binary_cb, each_hunk_cb, each_line_cb, &callbacks)
		
		return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_index_to_workdir"))
	}

	/// Create an instance with a libgit2 `git_diff`.
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
		refreshDeltas()
	}
	
	mutating private func refreshDeltas() {
		deltas.removeAll()
		for i in 0..<git_diff_num_deltas(pointer) {
			if let delta = git_diff_get_delta(pointer, i) {
				deltas.append(Diff.Delta(delta.pointee))
			}
		}
	}
}

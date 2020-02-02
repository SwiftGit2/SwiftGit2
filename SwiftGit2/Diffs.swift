//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public struct Diff {
	let pointer: OpaquePointer
	
	/// The set of deltas.
	public var deltas = [Delta]()

	

	public struct BinaryType : OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32
		
		public static let none 		= BinaryType(rawValue: GIT_DIFF_BINARY_NONE.rawValue)
		public static let literal	= BinaryType(rawValue: GIT_DIFF_BINARY_LITERAL.rawValue)
		public static let delta		= BinaryType(rawValue: GIT_DIFF_BINARY_DELTA.rawValue)
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
	
	mutating public func findSimilar(options: FindOptions) {
		var opt = git_diff_find_options(version: 1, flags: options.rawValue, rename_threshold: 50, rename_from_rewrite_threshold: 50, copy_threshold: 50, break_rewrite_threshold: 60, rename_limit: 200, metric: nil)
		git_diff_find_similar(pointer, &opt)
		
		refreshDeltas()
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

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

class DiffEachCallbacks {
	var deltas = [Diff.Delta]()
	
	let each_file_cb : git_diff_file_cb = { delta, progress, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.file(delta: Diff.Delta(delta.unsafelyUnwrapped.pointee), progress: progress)
		
		return 0
	}
	
	let each_line_cb : git_diff_line_cb = { delta, hunk, line, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.line(line: Diff.Line(line.unsafelyUnwrapped.pointee))
		
		return 0
	}
	
	let each_hunk_cb : git_diff_hunk_cb = { delta, hunk, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.hunk(hunk: Diff.Hunk(hunk.unsafelyUnwrapped.pointee))

		return 0
	}
		
	private func file(delta: Diff.Delta, progress: Float32) {
		deltas.append(delta)
	}
	
	private func hunk(hunk: Diff.Hunk) {
		guard let _ = deltas.last 				else { assert(false, "can't add hunk before adding delta"); return }
		
		deltas[deltas.count - 1].hunks.append(hunk)
	}
	
	private func line(line: Diff.Line) {
		guard let _ = deltas.last 				else { assert(false, "can't add line before adding delta"); return }
		guard let _ = deltas.last?.hunks.last 	else { assert(false, "can't add line before adding hunk"); return }
		
		let deltaIdx = deltas.count - 1
		let hunkIdx = deltas[deltaIdx].hunks.count - 1
		
		deltas[deltaIdx].hunks[hunkIdx].lines.append(line)
	}
}

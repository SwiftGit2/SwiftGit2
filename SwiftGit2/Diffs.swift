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


	/// Create an instance with a libgit2 `git_diff`.
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	public func findSimilar(options: FindOptions) -> Result<(), NSError> {
		var opt = git_diff_find_options(version: 1, flags: options.rawValue, rename_threshold: 50, rename_from_rewrite_threshold: 50, copy_threshold: 50, break_rewrite_threshold: 60, rename_limit: 200, metric: nil)
		
		return _result((), pointOfFailure: "git_diff_find_options") {
			git_diff_find_similar(pointer, &opt)
		}
	}

	public func patch() -> Result<Patch, NSError> {
		var pointer: OpaquePointer? = nil

		return _result( { Patch(pointer!) }, pointOfFailure: "git_patch_from_diff") {
			git_patch_from_diff(&pointer, self.pointer, 0)
		}

	}
}

public extension Diff {
	struct BinaryType : OptionSet {
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

	struct Flags: OptionSet {
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
	
	struct FindOptions: OptionSet {
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
}

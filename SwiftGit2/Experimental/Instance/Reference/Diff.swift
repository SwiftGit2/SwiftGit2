//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class Diff: InstanceProtocol {
    public let pointer: OpaquePointer

    /// Create an instance with a libgit2 `git_diff`.
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_diff_free(pointer)
    }

    public func findSimilar(options: FindOptions) -> Result<Diff, Error> {
        var opt = git_diff_find_options(version: 1, flags: options.rawValue, rename_threshold: 50, rename_from_rewrite_threshold: 50, copy_threshold: 50, break_rewrite_threshold: 60, rename_limit: 200, metric: nil)

        return git_try("git_diff_find_options") { git_diff_find_similar(pointer, &opt) }
            .map { self }
    }

    public func patch() -> Result<Patch, Error> {
        var pointer: OpaquePointer?

        return _result({ Patch(pointer!) }, pointOfFailure: "git_patch_from_diff") {
            git_patch_from_diff(&pointer, self.pointer, 0)
        }
    }
}

public extension Diff {
    struct BinaryType: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let none = BinaryType(rawValue: GIT_DIFF_BINARY_NONE.rawValue)
        public static let literal = BinaryType(rawValue: GIT_DIFF_BINARY_LITERAL.rawValue)
        public static let delta = BinaryType(rawValue: GIT_DIFF_BINARY_DELTA.rawValue)
    }

    struct Flags: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let binary = Flags(rawValue: GIT_DIFF_FLAG_BINARY.rawValue)
        public static let notBinary = Flags(rawValue: GIT_DIFF_FLAG_NOT_BINARY.rawValue)
        public static let validId = Flags(rawValue: GIT_DIFF_FLAG_VALID_ID.rawValue)
        public static let exists = Flags(rawValue: GIT_DIFF_FLAG_EXISTS.rawValue)
    }

    struct FindOptions: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let byConfig = FindOptions(rawValue: GIT_DIFF_FIND_BY_CONFIG.rawValue)
        public static let renames = FindOptions(rawValue: GIT_DIFF_FIND_RENAMES.rawValue)
        public static let renamesFromRewrites = FindOptions(rawValue: GIT_DIFF_FIND_RENAMES_FROM_REWRITES.rawValue)
        public static let copies = FindOptions(rawValue: GIT_DIFF_FIND_COPIES.rawValue)
        public static let copiesFromUnmodified = FindOptions(rawValue: GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED.rawValue)
        public static let rewrites = FindOptions(rawValue: GIT_DIFF_FIND_REWRITES.rawValue)
        public static let breakRewrites = FindOptions(rawValue: GIT_DIFF_BREAK_REWRITES.rawValue)
        public static let findAndBreakRewrites = FindOptions(rawValue: GIT_DIFF_FIND_AND_BREAK_REWRITES.rawValue)
        public static let forUntracked = FindOptions(rawValue: GIT_DIFF_FIND_FOR_UNTRACKED.rawValue)
        public static let all = FindOptions(rawValue: GIT_DIFF_FIND_ALL.rawValue)

        public static let ignoreLeadingWhitespace = FindOptions(rawValue: GIT_DIFF_FIND_IGNORE_LEADING_WHITESPACE.rawValue)
        public static let ignoreWhitespace = FindOptions(rawValue: GIT_DIFF_FIND_IGNORE_WHITESPACE.rawValue)
        public static let dontIgnoreWhitespace = FindOptions(rawValue: GIT_DIFF_FIND_DONT_IGNORE_WHITESPACE.rawValue)
        public static let exactMatchOnly = FindOptions(rawValue: GIT_DIFF_FIND_EXACT_MATCH_ONLY.rawValue)
        public static let breakRewritesForRenamesOnly = FindOptions(rawValue: GIT_DIFF_BREAK_REWRITES_FOR_RENAMES_ONLY.rawValue)
        public static let removeUnmodified = FindOptions(rawValue: GIT_DIFF_FIND_REMOVE_UNMODIFIED.rawValue)
    }
}

public enum SubmoduleIgnore_OLD: Int32 {
    case unspecified = -1 // GIT_SUBMODULE_IGNORE_UNSPECIFIED  = -1, /**< use the submodule's configuration */
    case none = 1 // GIT_SUBMODULE_IGNORE_NONE      = 1,  /**< any change or untracked == dirty */
    case untracked = 2 // GIT_SUBMODULE_IGNORE_UNTRACKED = 2,  /**< dirty if tracked files change */
    case ignoreDirty = 3 // GIT_SUBMODULE_IGNORE_DIRTY     = 3,  /**< only dirty if HEAD moved */
    case ignoreAll = 4 // GIT_SUBMODULE_IGNORE_ALL       = 4,  /**< never dirty */
}

public extension DiffOptions {
    struct Flags: OptionSet {
        public let rawValue: UInt32
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let normal = Flags(rawValue: GIT_DIFF_NORMAL.rawValue) /** Normal diff, the default */

        /*  Options controlling which files will be in the diff  */
        public static let reverse = Flags(rawValue: GIT_DIFF_REVERSE.rawValue) /** Reverse the sides of the diff */
        public static let includeIgnored = Flags(rawValue: GIT_DIFF_INCLUDE_IGNORED.rawValue) /** Include ignored files in the diff */
        public static let recurseIgnored = Flags(rawValue: GIT_DIFF_RECURSE_IGNORED_DIRS.rawValue) /** Even with GIT_DIFF_INCLUDE_IGNORED, an entire ignored directory will be marked with only a single entry in the diff; this flag  adds all files under the directory as IGNORED entries, too. */
        public static let includeUntracked = Flags(rawValue: GIT_DIFF_INCLUDE_UNTRACKED.rawValue) /** Include untracked files in the diff */
        public static let recurseUntracked = Flags(rawValue: GIT_DIFF_RECURSE_UNTRACKED_DIRS.rawValue) /** Even with GIT_DIFF_INCLUDE_UNTRACKED, an entire untracked directory will be marked with only a single entry in the diff (a la what core Git does in `git status`); this flag adds *all* files under untracked directories as UNTRACKED entries, too. */
        public static let includeUnmodified = Flags(rawValue: GIT_DIFF_INCLUDE_UNMODIFIED.rawValue)
        public static let includeTypechange = Flags(rawValue: GIT_DIFF_INCLUDE_TYPECHANGE.rawValue)
        public static let includeTypechangeTrees = Flags(rawValue: GIT_DIFF_INCLUDE_TYPECHANGE_TREES.rawValue)
        public static let ignoreFilemode = Flags(rawValue: GIT_DIFF_IGNORE_FILEMODE.rawValue)
        public static let ignoreSubmodules = Flags(rawValue: GIT_DIFF_IGNORE_SUBMODULES.rawValue)
        public static let ignoreCase = Flags(rawValue: GIT_DIFF_IGNORE_CASE.rawValue)
        public static let includeCaseChange = Flags(rawValue: GIT_DIFF_INCLUDE_CASECHANGE.rawValue)
        public static let disablePathspecMatch = Flags(rawValue: GIT_DIFF_DISABLE_PATHSPEC_MATCH.rawValue)
        public static let skipBinaryCheck = Flags(rawValue: GIT_DIFF_SKIP_BINARY_CHECK.rawValue)
        public static let enableFastUntrackedDirs = Flags(rawValue: GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS.rawValue)
        public static let updateIndex = Flags(rawValue: GIT_DIFF_UPDATE_INDEX.rawValue)
        public static let includeUnreadable = Flags(rawValue: GIT_DIFF_INCLUDE_UNREADABLE.rawValue)
        public static let includeUnreadableAsUntracked = Flags(rawValue: GIT_DIFF_INCLUDE_UNREADABLE_AS_UNTRACKED.rawValue)

        /*  Options controlling how output will be generated  */
        public static let indentHeuristic = Flags(rawValue: GIT_DIFF_INDENT_HEURISTIC.rawValue) /** Use a heuristic that takes indentation and whitespace into account which generally can produce better diffs when dealing with ambiguous diff hunks. */
        public static let forceText = Flags(rawValue: GIT_DIFF_FORCE_TEXT.rawValue) /** Treat all files as text, disabling binary attributes & detection */
        public static let forceBinary = Flags(rawValue: GIT_DIFF_FORCE_BINARY.rawValue) /** Treat all files as binary, disabling text diffs */
        public static let ignoreWhitespace = Flags(rawValue: GIT_DIFF_IGNORE_WHITESPACE.rawValue) /** Ignore all whitespace */
        public static let ignoreWhitespaceChange = Flags(rawValue: GIT_DIFF_IGNORE_WHITESPACE_CHANGE.rawValue) /** Ignore changes in amount of whitespace */
        public static let ingoreWhitespaceEOL = Flags(rawValue: GIT_DIFF_IGNORE_WHITESPACE_EOL.rawValue) /** Ignore whitespace at end of line */
        public static let showUntrackedContent = Flags(rawValue: GIT_DIFF_SHOW_UNTRACKED_CONTENT.rawValue) /** When generating patch text, include the content of untracked files.  This automatically turns on GIT_DIFF_INCLUDE_UNTRACKED but it does not turn on GIT_DIFF_RECURSE_UNTRACKED_DIRS.  Add that flag if you want the content of every single UNTRACKED file. */
        public static let showUnmodified = Flags(rawValue: GIT_DIFF_SHOW_UNMODIFIED.rawValue) /** When generating output, include the names of unmodified files if they are included in the git_diff.  Normally these are skipped in the formats that list files (e.g. name-only, name-status, raw). Even with this, these will not be included in patch format. */
        public static let patience = Flags(rawValue: GIT_DIFF_PATIENCE.rawValue) /** Use the "patience diff" algorithm */
        public static let minimal = Flags(rawValue: GIT_DIFF_MINIMAL.rawValue) /** Take extra time to find minimal diff */
        public static let binary = Flags(rawValue: GIT_DIFF_SHOW_BINARY.rawValue) /** 	Include the necessary deflate / delta information so that `git-apply` can apply given diff information to binary files. */
    }
}

////////////////////////////////////////////////////////////////////////////////
// DIFF APPLY
////////////////////////////////////////////////////////////////////////////////

public enum GitApplyLocation: UInt32 {
    case workdir = 0
    case index = 1
    case both = 2
}

public extension Repository {
    func apply(diff: Diff, location: GitApplyLocation, options: GitApplyOptions? = nil) -> Result<Void, Error> {
        return _result((), pointOfFailure: "git_apply") {
            git_apply(pointer, diff.pointer, git_apply_location_t(rawValue: location.rawValue), options?.pointer)
        }
    }
}

public class GitApplyOptions {
    var pointer = UnsafeMutablePointer<git_apply_options>.allocate(capacity: 1)

    public var version: UInt32 { pointer.pointee.version }

    public var flags: Flags { get { Flags(rawValue: pointer.pointee.flags) } set { pointer.pointee.flags = newValue.rawValue } }

    public var payload: UnsafeMutableRawPointer? { get { pointer.pointee.payload } set { pointer.pointee.payload = newValue } }
    public var delta_cb: git_apply_delta_cb { get { pointer.pointee.delta_cb } set { pointer.pointee.delta_cb = newValue }}
    public var hunk_cb: git_apply_hunk_cb { get { pointer.pointee.hunk_cb } set { pointer.pointee.hunk_cb = newValue } }

    public init() {
        let result = git_apply_options_init(pointer, UInt32(GIT_APPLY_OPTIONS_VERSION))
        assert(result == GIT_OK.rawValue)
    }

    deinit {
        pointer.deallocate()
    }
}

public extension GitApplyOptions {
    struct Flags: OptionSet {
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let check = Flags(rawValue: GIT_APPLY_CHECK.rawValue)
    }

    static var checkOnly: GitApplyOptions {
        let opt = GitApplyOptions()
        opt.flags = [.check]
        return opt
    }
}

/*
 typedef struct {
 	unsigned int version;      /** < version for the struct */

 	/**
 	 * A combination of `git_diff_option_t` values above.
 	 * Defaults to GIT_DIFF_NORMAL
 	 */
 	uint32_t flags;

 	/* options controlling which files are in the diff */

 	/** Overrides the submodule ignore setting for all submodules in the diff. */
 	git_submodule_ignore_t ignore_submodules;

 	/**
 	 * An array of paths / fnmatch patterns to constrain diff.
 	 * All paths are included by default.
 	 */
 	git_strarray       pathspec;

 	/**
 	 * An optional callback function, notifying the consumer of changes to
 	 * the diff as new deltas are added.
 	 */
 	git_diff_notify_cb   notify_cb;

 	/**
 	 * An optional callback function, notifying the consumer of which files
 	 * are being examined as the diff is generated.
 	 */
 	git_diff_progress_cb progress_cb;

 	/** The payload to pass to the callback functions. */
 	void                *payload;

 	/* options controlling how to diff text is generated */

 	/**
 	 * The number of unchanged lines that define the boundary of a hunk
 	 * (and to display before and after). Defaults to 3.
 	 */
 	uint32_t    context_lines;
 	/**
 	 * The maximum number of unchanged lines between hunk boundaries before
 	 * the hunks will be merged into one. Defaults to 0.
 	 */
 	uint32_t    interhunk_lines;

 	/**
 	 * The abbreviation length to use when formatting object ids.
 	 * Defaults to the value of 'core.abbrev' from the config, or 7 if unset.
 	 */
 	uint16_t    id_abbrev;

 	/**
 	 * A size (in bytes) above which a blob will be marked as binary
 	 * automatically; pass a negative value to disable.
 	 * Defaults to 512MB.
 	 */
 	git_off_t   max_size;

 	/**
 	 * The virtual "directory" prefix for old file names in hunk headers.
 	 * Default is "a".
 	 */
 	const char *old_prefix;

 	/**
 	 * The virtual "directory" prefix for new file names in hunk headers.
 	 * Defaults to "b".
 	 */
 	const char *new_prefix;
 } git_diff_options;
 */

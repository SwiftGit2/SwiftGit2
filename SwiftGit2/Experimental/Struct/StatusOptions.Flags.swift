
import Clibgit2

public extension StatusOptions {
    /**
     * - GIT_STATUS_SHOW_INDEX_AND_WORKDIR is the default.  This roughly
     *   matches `git status --porcelain` regarding which files are
     *   included and in what order.
     * - GIT_STATUS_SHOW_INDEX_ONLY only gives status based on HEAD to index
     *   comparison, not looking at working directory changes.
     * - GIT_STATUS_SHOW_WORKDIR_ONLY only gives status based on index to
     *   working directory comparison, not comparing the index to the HEAD.
     */

    enum Show: UInt32 {
        case indexAndWorkdir = 0 // GIT_STATUS_SHOW_INDEX_AND_WORKDIR
        case indexOnly = 1 // GIT_STATUS_SHOW_INDEX_ONLY
        case workdirOnly = 2 // GIT_STATUS_SHOW_WORKDIR_ONLY
    }
}

public extension StatusOptions {
    /**
     * - GIT_STATUS_OPT_INCLUDE_UNTRACKED says that callbacks should be made
     *   on untracked files.  These will only be made if the workdir files are
     *   included in the status "show" option.
     * - GIT_STATUS_OPT_INCLUDE_IGNORED says that ignored files get callbacks.
     *   Again, these callbacks will only be made if the workdir files are
     *   included in the status "show" option.
     * - GIT_STATUS_OPT_INCLUDE_UNMODIFIED indicates that callback should be
     *   made even on unmodified files.
     * - GIT_STATUS_OPT_EXCLUDE_SUBMODULES indicates that submodules should be
     *   skipped.  This only applies if there are no pending typechanges to
     *   the submodule (either from or to another type).
     * - GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS indicates that all files in
     *   untracked directories should be included.  Normally if an entire
     *   directory is new, then just the top-level directory is included (with
     *   a trailing slash on the entry name).  This flag says to include all
     *   of the individual files in the directory instead.
     * - GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH indicates that the given path
     *   should be treated as a literal path, and not as a pathspec pattern.
     * - GIT_STATUS_OPT_RECURSE_IGNORED_DIRS indicates that the contents of
     *   ignored directories should be included in the status.  This is like
     *   doing `git ls-files -o -i --exclude-standard` with core git.
     * - GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX indicates that rename detection
     *   should be processed between the head and the index and enables
     *   the GIT_STATUS_INDEX_RENAMED as a possible status flag.
     * - GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR indicates that rename
     *   detection should be run between the index and the working directory
     *   and enabled GIT_STATUS_WT_RENAMED as a possible status flag.
     * - GIT_STATUS_OPT_SORT_CASE_SENSITIVELY overrides the native case
     *   sensitivity for the file system and forces the output to be in
     *   case-sensitive order
     * - GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY overrides the native case
     *   sensitivity for the file system and forces the output to be in
     *   case-insensitive order
     * - GIT_STATUS_OPT_RENAMES_FROM_REWRITES indicates that rename detection
     *   should include rewritten files
     * - GIT_STATUS_OPT_NO_REFRESH bypasses the default status behavior of
     *   doing a "soft" index reload (i.e. reloading the index data if the
     *   file on disk has been modified outside libgit2).
     * - GIT_STATUS_OPT_UPDATE_INDEX tells libgit2 to refresh the stat cache
     *   in the index for files that are unchanged but have out of date stat
     *   information in the index.  It will result in less work being done on
     *   subsequent calls to get status.  This is mutually exclusive with the
     *   NO_REFRESH option.
     *
     * Calling `git_status_foreach()` is like calling the extended version
     * with: GIT_STATUS_OPT_INCLUDE_IGNORED, GIT_STATUS_OPT_INCLUDE_UNTRACKED,
     * and GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS.  Those options are bundled
     * together as `GIT_STATUS_OPT_DEFAULTS` if you want them as a baseline.
     */

    struct Flags: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let includeUntracked = Flags(rawValue: GIT_STATUS_OPT_INCLUDE_UNTRACKED.rawValue)
        public static let includeIgnored = Flags(rawValue: GIT_STATUS_OPT_INCLUDE_IGNORED.rawValue)
        public static let includeUnmodified = Flags(rawValue: GIT_STATUS_OPT_INCLUDE_UNMODIFIED.rawValue)
        public static let excludeSubmodules = Flags(rawValue: GIT_STATUS_OPT_EXCLUDE_SUBMODULES.rawValue)

        public static let recurseUntrackedDirs = Flags(rawValue: GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS.rawValue)
        public static let disablePathspecMatch = Flags(rawValue: GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH.rawValue)
        public static let recurseIgnoredDirs = Flags(rawValue: GIT_STATUS_OPT_RECURSE_IGNORED_DIRS.rawValue)
        public static let renamesHeadToIndex = Flags(rawValue: GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX.rawValue)

        public static let renamesIndexToWorkdir = Flags(rawValue: GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR.rawValue)
        public static let sortCaseSesitively = Flags(rawValue: GIT_STATUS_OPT_SORT_CASE_SENSITIVELY.rawValue)
        public static let sortCaseInsesitively = Flags(rawValue: GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY.rawValue)
        public static let renamesFromRewrites = Flags(rawValue: GIT_STATUS_OPT_RENAMES_FROM_REWRITES.rawValue)

        public static let noRefresh = Flags(rawValue: GIT_STATUS_OPT_NO_REFRESH.rawValue)
        public static let updateIndex = Flags(rawValue: GIT_STATUS_OPT_UPDATE_INDEX.rawValue)
        public static let includeUnreadable = Flags(rawValue: GIT_STATUS_OPT_INCLUDE_UNREADABLE.rawValue)
        public static let includeUnreadableAsUntracked = Flags(rawValue: GIT_STATUS_OPT_INCLUDE_UNREADABLE_AS_UNTRACKED.rawValue)
    }
}

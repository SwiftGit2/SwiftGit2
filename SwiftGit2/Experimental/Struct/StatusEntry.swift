
import Clibgit2
import Essentials

extension StatusEntry: Identifiable {
    public var id: String {
        var finalId: String = ""

        if let newPath = indexToWorkDir?.newFile?.path { finalId += newPath }

        if let oldPath = indexToWorkDir?.oldFile?.path { finalId += oldPath }

        if let newPath = headToIndex?.newFile?.path { finalId += newPath }

        if let oldPath = headToIndex?.oldFile?.path { finalId += oldPath }

        return finalId
    }
}

public struct StatusEntry {
    public let status: Status
    public let headToIndex: Diff.Delta?
    public let indexToWorkDir: Diff.Delta?

    public init(from statusEntry: git_status_entry) {
        status = Status(rawValue: statusEntry.status.rawValue)

        if let htoi = statusEntry.head_to_index {
            headToIndex = Diff.Delta(htoi.pointee)
        } else {
            headToIndex = nil
        }

        if let itow = statusEntry.index_to_workdir {
            indexToWorkDir = Diff.Delta(itow.pointee)
        } else {
            indexToWorkDir = nil
        }
    }
}

public extension StatusEntry {
    struct Status: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let current = Status(rawValue: GIT_STATUS_CURRENT.rawValue)
        public static let indexNew = Status(rawValue: GIT_STATUS_INDEX_NEW.rawValue)
        public static let indexModified = Status(rawValue: GIT_STATUS_INDEX_MODIFIED.rawValue)
        public static let indexDeleted = Status(rawValue: GIT_STATUS_INDEX_DELETED.rawValue)
        public static let indexRenamed = Status(rawValue: GIT_STATUS_INDEX_RENAMED.rawValue)
        public static let indexTypeChange = Status(rawValue: GIT_STATUS_INDEX_TYPECHANGE.rawValue)
        public static let workTreeNew = Status(rawValue: GIT_STATUS_WT_NEW.rawValue)
        public static let workTreeModified = Status(rawValue: GIT_STATUS_WT_MODIFIED.rawValue)
        public static let workTreeDeleted = Status(rawValue: GIT_STATUS_WT_DELETED.rawValue)
        public static let workTreeTypeChange = Status(rawValue: GIT_STATUS_WT_TYPECHANGE.rawValue)
        public static let workTreeRenamed = Status(rawValue: GIT_STATUS_WT_RENAMED.rawValue)
        public static let workTreeUnreadable = Status(rawValue: GIT_STATUS_WT_UNREADABLE.rawValue)
        public static let ignored = Status(rawValue: GIT_STATUS_IGNORED.rawValue)
        public static let conflicted = Status(rawValue: GIT_STATUS_CONFLICTED.rawValue)
    }
}

public extension UiStatusEntryX {
    var headToIndexNEWFilePath : R<String> {
        unStagedDeltas.asNonOptional("headToIndex") | { $0.newFilePath }
    }
    
    var headToIndexOLDFilePath : R<String> {
        unStagedDeltas.asNonOptional("headToIndex") | { $0.oldFilePath }
    }
    
    var indexToWorkDirNEWFilePath : R<String> {
        stagedDeltas.asNonOptional("indexToWorkDir") | { $0.newFilePath }
    }
    
    var indexToWorkDirOLDFilePath : R<String> {
        stagedDeltas.asNonOptional("indexToWorkDir") | { $0.newFilePath }
    }

}

public extension Duo where T1 == UiStatusEntryX, T2 == Repository {
    var headToIndexNewFileURL : R<URL> {
        let (entry, repo) = self.value
        let path = entry.headToIndexNEWFilePath
        return combine(repo.directoryURL, path) | { $0.appendingPathComponent($1) }
    }
    
    var indexToWorkDirNewFileURL : R<URL> {
        let (entry, repo) = self.value
        let path = entry.indexToWorkDirNEWFilePath
        return combine(repo.directoryURL, path) | { $0.appendingPathComponent($1) }
    }
}

public extension Diff.Delta {
    var newFilePath : R<String> {
        self.newFile.asNonOptional("newFile") | { $0.path }
    }
    
    var oldFilePath : R<String> {
        self.oldFile.asNonOptional("oldFile") | { $0.path }
    }
}

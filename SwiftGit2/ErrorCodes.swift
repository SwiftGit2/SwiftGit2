import Foundation
import Clibgit2

/// The underlying error generated by libgit2
public struct Libgit2Error: Error, CustomStringConvertible, Equatable {
	public let errorCode: git_error_code

	/// The libgit2 function that produced the error
	public let source: Libgit2Method

	/// The type of underlying error
	public let errorType: Libgit2ErrorType

	public let errorMessage: String?

	public var description: String {
		"\(errorMessage ?? errorCode.description), type: \(errorType), source: \(source)"
	}

	internal init(errorCode: Int32, source: Libgit2Method) {
		self.errorCode = git_error_code(rawValue: errorCode)
		self.source = source
		let (type, message) = Libgit2Error.getLatestType()
		self.errorType = type
		self.errorMessage = message
	}

	internal static func getLatestType() -> (type: Libgit2ErrorType, errorMessage: String?) {
		let last = giterr_last()
		guard let lastErrorPointer = last else {
			return (type: .none, errorMessage: nil)
		}
		let errorType = git_error_t(rawValue: UInt32(lastErrorPointer.pointee.klass))
		let type = Libgit2ErrorType(rawValue: errorType)
		let errorMessage = String(validatingUTF8: lastErrorPointer.pointee.message)
		return (type: type, errorMessage: errorMessage)
	}
}

/// Source Libit2 method where an error was reported
public enum Libgit2Method {
	case git_repository_init
	case git_signature_new
	case git_repository_open
	case git_clone
	case git_object_lookup
	case git_remote_list
	case git_remote_lookup
	case git_remote_fetch
	case git_reference_list
	case git_reference_lookup
	case git_repository_head
	case git_repository_set_head
	case git_checkout_head
	case git_repository_index
	case git_index_add_all
	case git_index_write
	case git_tree_lookup
	case git_commit_lookup
	case git_commit_create
	case git_index_write_tree
	case git_reference_name_to_id
	case git_diff_merge
	case git_diff_tree_to_tree
	case git_status_init_options
	case git_status_list_new
	case git_repository_open_ext
	case git_revwalk_next
}

extension git_error_code: CustomStringConvertible {
	public var description: String {
		switch self {
		case GIT_OK:
			return "No error"
		case GIT_ERROR:
			return "Generic error"
		case GIT_ENOTFOUND:
			return "Requested object could not be found"
		case GIT_EEXISTS:
			return "Object exists preventing operation"
		case GIT_EAMBIGUOUS:
			return "More than one object matches"
		case GIT_EBUFS:
			return "Output buffer too short to hold data"
		case GIT_EUSER:
			return "A special error that is never generated by libgit2"
		case GIT_EBAREREPO:
			return "Operation not allowed on bare repository"
		case GIT_EUNBORNBRANCH:
			return "HEAD refers to branch with no commits"
		case GIT_EUNMERGED:
			return "Merge in progress prevented operation"
		case GIT_ENONFASTFORWARD:
			return "Reference was not fast-forwardable"
		case GIT_EINVALIDSPEC:
			return "Name/ref spec was not in a valid format"
		case GIT_ECONFLICT:
			return "Checkout conflicts prevented operation"
		case GIT_ELOCKED:
			return "Lock file prevented operation"
		case GIT_EMODIFIED:
			return "Reference value does not match expected"
		case GIT_EAUTH:
			return "Authentication error"
		case GIT_ECERTIFICATE:
			return "Server certificate is invalid"
		case GIT_EAPPLIED:
			return "Patch/merge has already been applied"
		case GIT_EPEEL:
			return "The requested peel operation is not possible"
		case GIT_EEOF:
			return "Unexpected EOF"
		case GIT_EINVALID:
			return "Invalid operation or input"
		case GIT_EUNCOMMITTED:
			return "Uncommitted changes in index prevented operation"
		case GIT_EDIRECTORY:
			return "The operation is not valid for a directory"
		case GIT_EMERGECONFLICT:
			return "A merge conflict exists and cannot continue"
		case GIT_PASSTHROUGH:
			return "Internal only"
		case GIT_ITEROVER:
			return "Signals end of iteration with iterator"
		case GIT_RETRY:
			return "Internal only"
		case GIT_EMISMATCH:
			return "Hashsum mismatch in object"
		default:
			return "Unknown Error Code: \(self)"
		}
	}
}

public enum Libgit2ErrorType {
	case none
	case noMemory
	case os
	case invalid
	case reference
	case zlib
	case repository
	case config
	case regex
	case odb
	case index
	case object
	case net
	case tag
	case tree
	case indexer
	case ssl
	case submodule
	case thread
	case stash
	case checkout
	case fetchHead
	case merge
	case ssh
	case filter
	case revert
	case callback
	case cherryPick
	case describe
	case rebase
	case fileSystem
	case patch
	case workTree
	case sha1
}

extension Libgit2ErrorType: RawRepresentable {
	public init(rawValue: git_error_t) {
		switch rawValue {
		case GITERR_NOMEMORY:
			self = .noMemory
		case GITERR_OS:
			self = .os
		case GITERR_INVALID:
			self = .invalid
		case GITERR_REFERENCE:
			self = .reference
		case GITERR_ZLIB:
			self = .zlib
		case GITERR_REPOSITORY:
			self = .repository
		case GITERR_CONFIG:
			self = .config
		case GITERR_REGEX:
			self = .regex
		case GITERR_ODB:
			self = .odb
		case GITERR_INDEX:
			self = .index
		case GITERR_OBJECT:
			self = .object
		case GITERR_NET:
			self = .net
		case GITERR_TAG:
			self = .tag
		case GITERR_TREE:
			self = .tree
		case GITERR_INDEXER:
			self = .indexer
		case GITERR_SSL:
			self = .ssl
		case GITERR_SUBMODULE:
			self = .submodule
		case GITERR_THREAD:
			self = .thread
		case GITERR_STASH:
			self = .stash
		case GITERR_CHECKOUT:
			self = .checkout
		case GITERR_FETCHHEAD:
			self = .fetchHead
		case GITERR_MERGE:
			self = .merge
		case GITERR_SSH:
			self = .ssh
		case GITERR_FILTER:
			self = .filter
		case GITERR_REVERT:
			self = .revert
		case GITERR_CALLBACK:
			self = .callback
		case GITERR_CHERRYPICK:
			self = .cherryPick
		case GITERR_DESCRIBE:
			self = .describe
		case GITERR_REBASE:
			self = .rebase
		case GITERR_FILESYSTEM:
			self = .fileSystem
		case GITERR_PATCH:
			self = .patch
		case GITERR_WORKTREE:
			self = .workTree
		case GITERR_SHA1:
			self = .sha1
		default:
			self = .none
		}
	}

	public var rawValue: git_error_t {
		switch self {
		case .none:
			return GITERR_NONE
		case .noMemory:
			return GITERR_NOMEMORY
		case .os:
			return GITERR_OS
		case .invalid:
			return GITERR_INVALID
		case .reference:
			return GITERR_REFERENCE
		case .zlib:
			return GITERR_ZLIB
		case .repository:
			return GITERR_REPOSITORY
		case .config:
			return GITERR_CONFIG
		case .regex:
			return GITERR_REGEX
		case .odb:
			return GITERR_ODB
		case .index:
			return GITERR_INDEX
		case .object:
			return GITERR_OBJECT
		case .net:
			return GITERR_NET
		case .tag:
			return GITERR_TAG
		case .tree:
			return GITERR_TREE
		case .indexer:
			return GITERR_INDEXER
		case .ssl:
			return GITERR_SSL
		case .submodule:
			return GITERR_SUBMODULE
		case .thread:
			return GITERR_THREAD
		case .stash:
			return GITERR_STASH
		case .checkout:
			return GITERR_CHECKOUT
		case .fetchHead:
			return GITERR_FETCHHEAD
		case .merge:
			return GITERR_MERGE
		case .ssh:
			return GITERR_SSH
		case .filter:
			return GITERR_FILTER
		case .revert:
			return GITERR_REVERT
		case .callback:
			return GITERR_CALLBACK
		case .cherryPick:
			return GITERR_CHERRYPICK
		case .describe:
			return GITERR_DESCRIBE
		case .rebase:
			return GITERR_REBASE
		case .fileSystem:
			return GITERR_FILESYSTEM
		case .patch:
			return GITERR_PATCH
		case .workTree:
			return GITERR_WORKTREE
		case .sha1:
			return GITERR_SHA1
		}
	}
}
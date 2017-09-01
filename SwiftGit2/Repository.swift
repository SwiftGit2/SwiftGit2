//
//  Repository.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import Result
import libgit2

public typealias CheckoutProgressBlock = (String?, Int, Int) -> Void

/// Helper function used as the libgit2 progress callback in git_checkout_options.
/// This is a function with a type signature of git_checkout_progress_cb.
private func checkoutProgressCallback(path: UnsafePointer<Int8>?, completedSteps: Int, totalSteps: Int,
                                      payload: UnsafeMutableRawPointer?) {
	if let payload = payload {
		let buffer = payload.assumingMemoryBound(to: CheckoutProgressBlock.self)
		let block: CheckoutProgressBlock
		if completedSteps < totalSteps {
			block = buffer.pointee
		} else {
			block = buffer.move()
			buffer.deallocate(capacity: 1)
		}
		block(path.flatMap(String.init(validatingUTF8:)), completedSteps, totalSteps)
	}
}

/// Helper function for initializing libgit2 git_checkout_options.
///
/// :param: strategy The strategy to be used when checking out the repo, see CheckoutStrategy
/// :param: progress A block that's called with the progress of the checkout.
/// :returns: Returns a git_checkout_options struct with the progress members set.
private func checkoutOptions(strategy: CheckoutStrategy,
                             progress: CheckoutProgressBlock? = nil) -> git_checkout_options {
	// Do this because GIT_CHECKOUT_OPTIONS_INIT is unavailable in swift
	let pointer = UnsafeMutablePointer<git_checkout_options>.allocate(capacity: 1)
	git_checkout_init_options(pointer, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
	var options = pointer.move()
	pointer.deallocate(capacity: 1)

	options.checkout_strategy = strategy.gitCheckoutStrategy.rawValue

	if progress != nil {
		options.progress_cb = checkoutProgressCallback
		let blockPointer = UnsafeMutablePointer<CheckoutProgressBlock>.allocate(capacity: 1)
		blockPointer.initialize(to: progress!)
		options.progress_payload = UnsafeMutableRawPointer(blockPointer)
	}

	return options
}

private func fetchOptions(credentials: Credentials) -> git_fetch_options {
	let pointer = UnsafeMutablePointer<git_fetch_options>.allocate(capacity: 1)
	git_fetch_init_options(pointer, UInt32(GIT_FETCH_OPTIONS_VERSION))

	var options = pointer.move()

	pointer.deallocate(capacity: 1)

	options.callbacks.payload = credentials.toPointer()
	options.callbacks.credentials = credentialsCallback

	return options
}

private func cloneOptions(bare: Bool = false, localClone: Bool = false, fetchOptions: git_fetch_options? = nil,
                          checkoutOptions: git_checkout_options? = nil) -> git_clone_options {
	let pointer = UnsafeMutablePointer<git_clone_options>.allocate(capacity: 1)
	git_clone_init_options(pointer, UInt32(GIT_CLONE_OPTIONS_VERSION))

	var options = pointer.move()

	pointer.deallocate(capacity: 1)

	options.bare = bare ? 1 : 0

	if localClone {
		options.local = GIT_CLONE_NO_LOCAL
	}

	if let checkoutOptions = checkoutOptions {
		options.checkout_opts = checkoutOptions
	}

	if let fetchOptions = fetchOptions {
		options.fetch_opts = fetchOptions
	}

	return options
}

/// A git repository.
final public class Repository {

	// MARK: - Creating Repositories

	/// Create a new repository at the given URL.
	///
	/// URL - The URL of the repository.
	///
	/// Returns a `Result` with a `Repository` or an error.
	class public func create(at url: URL) -> Result<Repository, NSError> {
		var pointer: OpaquePointer? = nil
		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_init(&pointer, $0, 0)
		}

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_init"))
		}

		let repository = Repository(pointer!)
		return Result.success(repository)
	}

	/// Load the repository at the given URL.
	///
	/// URL - The URL of the repository.
	///
	/// Returns a `Result` with a `Repository` or an error.
	class public func at(_ url: URL) -> Result<Repository, NSError> {
		var pointer: OpaquePointer? = nil
		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_open(&pointer, $0)
		}

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
		}

		let repository = Repository(pointer!)
		return Result.success(repository)
	}

	/// Clone the repository from a given URL.
	///
	/// remoteURL        - The URL of the remote repository
	/// localURL         - The URL to clone the remote repository into
	/// localClone       - Will not bypass the git-aware transport, even if remote is local.
	/// bare             - Clone remote as a bare repository.
	/// credentials      - Credentials to be used when connecting to the remote.
	/// checkoutStrategy - The checkout strategy to use, if being checked out.
	/// checkoutProgress - A block that's called with the progress of the checkout.
	///
	/// Returns a `Result` with a `Repository` or an error.
	class public func clone(from remoteURL: URL, to localURL: URL, localClone: Bool = false, bare: Bool = false,
	                        credentials: Credentials = .default, checkoutStrategy: CheckoutStrategy = .Safe,
	                        checkoutProgress: CheckoutProgressBlock? = nil) -> Result<Repository, NSError> {
			var options = cloneOptions(
				bare: bare, localClone: localClone,
				fetchOptions: fetchOptions(credentials: credentials),
				checkoutOptions: checkoutOptions(strategy: checkoutStrategy, progress: checkoutProgress))

			var pointer: OpaquePointer? = nil
			let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString
			let result = localURL.withUnsafeFileSystemRepresentation { localPath in
				git_clone(&pointer, remoteURLString, localPath, &options)
			}

			guard result == GIT_OK.rawValue else {
				return Result.failure(NSError(gitError: result, pointOfFailure: "git_clone"))
			}

			let repository = Repository(pointer!)
			return Result.success(repository)
	}

	// MARK: - Initializers

	/// Create an instance with a libgit2 `git_repository` object.
	///
	/// The Repository assumes ownership of the `git_repository` object.
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer

		let path = git_repository_workdir(pointer)
		self.directoryURL = path.map({ URL(fileURLWithPath: String(validatingUTF8: $0)!, isDirectory: true) })
	}

	deinit {
		git_repository_free(pointer)
	}

	// MARK: - Properties

	/// The underlying libgit2 `git_repository` object.
	public let pointer: OpaquePointer

	/// The URL of the repository's working directory, or `nil` if the
	/// repository is bare.
	public let directoryURL: URL?

	// MARK: - Object Lookups

	/// Load a libgit2 object and transform it to something else.
	///
	/// oid       - The OID of the object to look up.
	/// type      - The type of the object to look up.
	/// transform - A function that takes the libgit2 object and transforms it
	///             into something else.
	///
	/// Returns the result of calling `transform` or an error if the object
	/// cannot be loaded.
	private func withGitObject<T>(_ oid: OID, type: git_otype,
	                              transform: (OpaquePointer) -> Result<T, NSError>) -> Result<T, NSError> {
		var pointer: OpaquePointer? = nil
		var oid = oid.oid
		let result = git_object_lookup(&pointer, self.pointer, &oid, type)

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_object_lookup"))
		}

		let value = transform(pointer!)
		git_object_free(pointer)
		return value
	}

	private func withGitObject<T>(_ oid: OID, type: git_otype, transform: (OpaquePointer) -> T) -> Result<T, NSError> {
		return withGitObject(oid, type: type) { Result.success(transform($0)) }
	}

	/// Loads the object with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns a `Blob`, `Commit`, `Tag`, or `Tree` if one exists, or an error.
	public func object(_ oid: OID) -> Result<ObjectType, NSError> {
		return withGitObject(oid, type: GIT_OBJ_ANY) { object in
			let type = git_object_type(object)
			if type == Blob.type {
				return Result.success(Blob(object))
			} else if type == Commit.type {
				return Result.success(Commit(object))
			} else if type == Tag.type {
				return Result.success(Tag(object))
			} else if type == Tree.type {
				return Result.success(Tree(object))
			}

			let error = NSError(
				domain: "org.libgit2.SwiftGit2",
				code: 1,
				userInfo: [
					NSLocalizedDescriptionKey: "Unrecognized git_otype '\(type)' for oid '\(oid)'.",
				]
			)
			return Result.failure(error)
		}
	}

	/// Loads the blob with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns the blob if it exists, or an error.
	public func blob(_ oid: OID) -> Result<Blob, NSError> {
		return withGitObject(oid, type: GIT_OBJ_BLOB) { Blob($0) }
	}

	/// Loads the commit with the given OID.
	///
	/// oid - The OID of the commit to look up.
	///
	/// Returns the commit if it exists, or an error.
	public func commit(_ oid: OID) -> Result<Commit, NSError> {
		return withGitObject(oid, type: GIT_OBJ_COMMIT) { Commit($0) }
	}

	/// Loads the tag with the given OID.
	///
	/// oid - The OID of the tag to look up.
	///
	/// Returns the tag if it exists, or an error.
	public func tag(_ oid: OID) -> Result<Tag, NSError> {
		return withGitObject(oid, type: GIT_OBJ_TAG) { Tag($0) }
	}

	/// Loads the tree with the given OID.
	///
	/// oid - The OID of the tree to look up.
	///
	/// Returns the tree if it exists, or an error.
	public func tree(_ oid: OID) -> Result<Tree, NSError> {
		return withGitObject(oid, type: GIT_OBJ_TREE) { Tree($0) }
	}

	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func object<T>(from pointer: PointerTo<T>) -> Result<T, NSError> {
		return withGitObject(pointer.oid, type: pointer.type) { T($0) }
	}

	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func object(from pointer: Pointer) -> Result<ObjectType, NSError> {
		switch pointer {
		case let .blob(oid):
			return blob(oid).map { $0 as ObjectType }
		case let .commit(oid):
			return commit(oid).map { $0 as ObjectType }
		case let .tag(oid):
			return tag(oid).map { $0 as ObjectType }
		case let .tree(oid):
			return tree(oid).map { $0 as ObjectType }
		}
	}

	// MARK: - Remote Lookups

	/// Loads all the remotes in the repository.
	///
	/// Returns an array of remotes, or an error.
	public func allRemotes() -> Result<[Remote], NSError> {
		let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
		let result = git_remote_list(pointer, self.pointer)

		guard result == GIT_OK.rawValue else {
			pointer.deallocate(capacity: 1)
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_remote_list"))
		}

		let strarray = pointer.pointee
		let remotes: [Result<Remote, NSError>] = strarray.map {
			return self.remote(named: $0)
		}
		git_strarray_free(pointer)
		pointer.deallocate(capacity: 1)

		let error = remotes.reduce(nil) { $0 == nil ? $0 : $1.error }
		if let error = error {
			return Result.failure(error)
		}
		return Result.success(remotes.map { $0.value! })
	}

	/// Load a remote from the repository.
	///
	/// name - The name of the remote.
	///
	/// Returns the remote if it exists, or an error.
	public func remote(named name: String) -> Result<Remote, NSError> {
		var pointer: OpaquePointer? = nil
		let result = git_remote_lookup(&pointer, self.pointer, name)

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_remote_lookup"))
		}

		let value = Remote(pointer!)
		git_remote_free(pointer)
		return Result.success(value)
	}

	// MARK: - Reference Lookups

	/// Load all the references with the given prefix (e.g. "refs/heads/")
	public func references(withPrefix prefix: String) -> Result<[ReferenceType], NSError> {
		let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
		let result = git_reference_list(pointer, self.pointer)

		guard result == GIT_OK.rawValue else {
			pointer.deallocate(capacity: 1)
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_list"))
		}

		let strarray = pointer.pointee
		let references = strarray
			.filter {
				$0.hasPrefix(prefix)
			}
			.map {
				self.reference(named: $0)
			}
		git_strarray_free(pointer)
		pointer.deallocate(capacity: 1)

		let error = references.reduce(nil) { $0 == nil ? $0 : $1.error }
		if let error = error {
			return Result.failure(error)
		}
		return Result.success(references.map { $0.value! })
	}

	/// Load the reference with the given long name (e.g. "refs/heads/master")
	///
	/// If the reference is a branch, a `Branch` will be returned. If the
	/// reference is a tag, a `TagReference` will be returned. Otherwise, a
	/// `Reference` will be returned.
	public func reference(named name: String) -> Result<ReferenceType, NSError> {
		var pointer: OpaquePointer? = nil
		let result = git_reference_lookup(&pointer, self.pointer, name)

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_lookup"))
		}

		let value = referenceWithLibGit2Reference(pointer!)
		git_reference_free(pointer)
		return Result.success(value)
	}

	/// Load and return a list of all local branches.
	public func localBranches() -> Result<[Branch], NSError> {
		return references(withPrefix: "refs/heads/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! Branch }
			}
	}

	/// Load and return a list of all remote branches.
	public func remoteBranches() -> Result<[Branch], NSError> {
		return references(withPrefix: "refs/remotes/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! Branch }
			}
	}

	/// Load the local branch with the given name (e.g., "master").
	public func localBranch(named name: String) -> Result<Branch, NSError> {
		return reference(named: "refs/heads/" + name).map { $0 as! Branch }
	}

	/// Load the remote branch with the given name (e.g., "origin/master").
	public func remoteBranch(named name: String) -> Result<Branch, NSError> {
		return reference(named: "refs/remotes/" + name).map { $0 as! Branch }
	}

	/// Load and return a list of all the `TagReference`s.
	public func allTags() -> Result<[TagReference], NSError> {
		return references(withPrefix: "refs/tags/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! TagReference }
			}
	}

	/// Load the tag with the given name (e.g., "tag-2").
	public func tag(named name: String) -> Result<TagReference, NSError> {
		return reference(named: "refs/tags/" + name).map { $0 as! TagReference }
	}

	// MARK: - Working Directory

	/// Load the reference pointed at by HEAD.
	///
	/// When on a branch, this will return the current `Branch`.
	public func HEAD() -> Result<ReferenceType, NSError> {
		var pointer: OpaquePointer? = nil
		let result = git_repository_head(&pointer, self.pointer)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
		}
		let value = referenceWithLibGit2Reference(pointer!)
		git_reference_free(pointer)
		return Result.success(value)
	}

	/// Set HEAD to the given oid (detached).
	///
	/// :param: oid The OID to set as HEAD.
	/// :returns: Returns a result with void or the error that occurred.
	public func setHEAD(_ oid: OID) -> Result<(), NSError> {
		var oid = oid.oid
		let result = git_repository_set_head_detached(self.pointer, &oid)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head"))
		}
		return Result.success()
	}

	/// Set HEAD to the given reference.
	///
	/// :param: reference The reference to set as HEAD.
	/// :returns: Returns a result with void or the error that occurred.
	public func setHEAD(_ reference: ReferenceType) -> Result<(), NSError> {
		let result = git_repository_set_head(self.pointer, reference.longName)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head"))
		}
		return Result.success()
	}

	/// Check out HEAD.
	///
	/// :param: strategy The checkout strategy to use.
	/// :param: progress A block that's called with the progress of the checkout.
	/// :returns: Returns a result with void or the error that occurred.
	public func checkout(strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> Result<(), NSError> {
		var options = checkoutOptions(strategy: strategy, progress: progress)

		let result = git_checkout_head(self.pointer, &options)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_checkout_head"))
		}

		return Result.success()
	}

	/// Check out the given OID.
	///
	/// :param: oid The OID of the commit to check out.
	/// :param: strategy The checkout strategy to use.
	/// :param: progress A block that's called with the progress of the checkout.
	/// :returns: Returns a result with void or the error that occurred.
	public func checkout(_ oid: OID, strategy: CheckoutStrategy,
	                     progress: CheckoutProgressBlock? = nil) -> Result<(), NSError> {
		return setHEAD(oid).flatMap { self.checkout(strategy: strategy, progress: progress) }
	}

	/// Check out the given reference.
	///
	/// :param: reference The reference to check out.
	/// :param: strategy The checkout strategy to use.
	/// :param: progress A block that's called with the progress of the checkout.
	/// :returns: Returns a result with void or the error that occurred.
	public func checkout(_ reference: ReferenceType, strategy: CheckoutStrategy,
	                     progress: CheckoutProgressBlock? = nil) -> Result<(), NSError> {
		return setHEAD(reference).flatMap { self.checkout(strategy: strategy, progress: progress) }
	}

	/// Load all commits in the specified branch in topological & time order descending
	///
	/// :param: branch The branch to get all commits from
	/// :returns: Returns a result with array of branches or the error that occurred
	public func commits(in branch: Branch) -> CommitIterator {
		let iterator = CommitIterator(repo: self, root: branch.oid.oid)
		return iterator
	}

	// MARK: - Diffs

	public func getDiffDeltas(for commit: Commit) -> Result<[DiffDelta], NSError> {
		/// Get the Base Tree
		var unsafeBaseCommit: OpaquePointer? = nil
		let unsafeBaseOid = UnsafeMutablePointer<git_oid>.allocate(capacity: 1)
		git_oid_fromstr(unsafeBaseOid, commit.oid.description)
		let lookupBaseGitResult = git_commit_lookup(&unsafeBaseCommit, self.pointer, unsafeBaseOid)
		guard lookupBaseGitResult == GIT_OK.rawValue, let unwrapBaseCommit = unsafeBaseCommit else {
				return Result.failure(NSError(gitError: lookupBaseGitResult, pointOfFailure: "git_commit_lookup"))
		}
		git_commit_free(unsafeBaseCommit)

		var unsafeBaseTree: OpaquePointer? = nil
		let baseTreeResult = git_commit_tree(&unsafeBaseTree, unwrapBaseCommit)
		guard baseTreeResult == GIT_OK.rawValue, let unwrapBaseTree = unsafeBaseTree else {
			return Result.failure(NSError(gitError: baseTreeResult, pointOfFailure: "git_commit_tree"))
		}
		git_tree_free(unsafeBaseTree)

		if commit.parents.isEmpty {
			// Initial commit in a repository
			var unsafeDiff: OpaquePointer? = nil
			let diffResult = git_diff_tree_to_tree(&unsafeDiff, self.pointer, nil, unwrapBaseTree, nil)
			guard diffResult == GIT_OK.rawValue, let unwrapDiffResult = unsafeDiff else {
				return Result.failure(NSError(gitError: diffResult, pointOfFailure: "git_diff_tree_to_tree"))
			}

			return self.processDiffDeltas(unwrapDiffResult)
		} else {
			// Possible Merge Commit, merge diffs of base with each parent
			var mergeDiff: OpaquePointer? = nil
			for parent in commit.parents {
				var unsafeParentCommit: OpaquePointer? = nil
				let unsafeParentOid = UnsafeMutablePointer<git_oid>.allocate(capacity: 1)
				git_oid_fromstr(unsafeParentOid, parent.oid.description)
				let lookupParentGitResult = git_commit_lookup(&unsafeParentCommit, self.pointer, unsafeParentOid)
				guard lookupParentGitResult == GIT_OK.rawValue, let unwrapParentCommit = unsafeParentCommit else {
					return Result.failure(NSError(gitError: lookupParentGitResult, pointOfFailure: "git_commit_lookup"))
				}
				git_commit_free(unsafeParentCommit)

				var unsafeParentTree: OpaquePointer? = nil
				let parentTreeResult = git_commit_tree(&unsafeParentTree, unwrapParentCommit)
				guard parentTreeResult == GIT_OK.rawValue, let unwrapParentTree = unsafeParentTree else {
					return Result.failure(NSError(gitError: parentTreeResult, pointOfFailure: "git_commit_tree"))
				}
				git_tree_free(unsafeParentTree)

				var unsafeDiff: OpaquePointer? = nil
				let diffResult = git_diff_tree_to_tree(&unsafeDiff, self.pointer, unwrapParentTree, unwrapBaseTree, nil)
				guard diffResult == GIT_OK.rawValue, let unwrapDiffResult = unsafeDiff else {
					return Result.failure(NSError(gitError: diffResult, pointOfFailure: "git_diff_tree_to_tree"))
				}

				if mergeDiff == nil {
					mergeDiff = unwrapDiffResult
				} else {
					let mergeResult = git_diff_merge(mergeDiff, unwrapDiffResult)
					guard mergeResult == GIT_OK.rawValue else {
						return Result.failure(NSError(gitError: mergeResult, pointOfFailure: "git_diff_merge"))
					}
				}
			}
			return self.processDiffDeltas(mergeDiff!)
		}
	}

	private func processDiffDeltas(_ diffResult: OpaquePointer) -> Result<[DiffDelta], NSError> {
		var returnDict = [DiffDelta]()

		let count = git_diff_num_deltas(diffResult)

		for i in 0..<count {
			let delta = git_diff_get_delta(diffResult, i)

			let oldFilePath = (delta?.pointee.old_file.path!).map(String.init(cString:))
			let oldOid = OID((delta?.pointee.old_file.id)!)
			let oldSize = delta?.pointee.old_file.size
			let oldFlags = delta?.pointee.old_file.flags
			let oldFile = DiffFile(oid: oldOid, path: oldFilePath!, size: oldSize!, flags: oldFlags!)

			let newFilePath = (delta?.pointee.new_file.path!).map(String.init(cString:))
			let newOid = OID((delta?.pointee.new_file.id)!)
			let newSize = delta?.pointee.new_file.size
			let newFlags = delta?.pointee.new_file.flags
			let newFile = DiffFile(oid: newOid, path: newFilePath!, size: newSize!, flags: newFlags!)

			var gitDeltaStatus = Status.current

			let emptyOid = OID(string: "0000000000000000000000000000000000000000")
			if newOid == emptyOid {
				gitDeltaStatus = Status.indexDeleted
			} else if oldOid == emptyOid {
				gitDeltaStatus = Status.indexNew
			} else {
				if let statusValue = delta?.pointee.status.rawValue {
					if (statusValue & Status.current.rawValue) != 0 {
					}
					if (statusValue & Status.indexModified.rawValue) != 0 {
						gitDeltaStatus = Status.indexModified
					}
					if (statusValue & Status.indexRenamed.rawValue) != 0 {
						gitDeltaStatus = Status.indexRenamed
					}
					if (statusValue & Status.indexTypeChange.rawValue) != 0 {
						gitDeltaStatus = Status.indexTypeChange
					}
					if (statusValue & Status.ignored.rawValue) != 0 {
						gitDeltaStatus = Status.ignored
					}
					if (statusValue & Status.conflicted.rawValue) != 0 {
						gitDeltaStatus = Status.conflicted
					}
				}
			}

			let gitDiffDelta = DiffDelta(status: gitDeltaStatus,
			                             flags: (delta?.pointee.flags)!,
			                             oldFile: oldFile,
			                             newFile: newFile)

			returnDict.append(gitDiffDelta)

			git_diff_free(OpaquePointer(delta))
		}

		let result = Result<[DiffDelta], NSError>.success(returnDict)
		return result
	}

	// MARK: - Status

	public func getRepositoryStatus() -> Result<[StatusEntry], NSError> {

		var returnArray = [StatusEntry]()

		// Do this because GIT_STATUS_OPTIONS_INIT is unavailable in swift
		let pointer = UnsafeMutablePointer<git_status_options>.allocate(capacity: 1)
		git_status_init_options(pointer, UInt32(GIT_STATUS_OPTIONS_VERSION))
		var options = pointer.move()
		pointer.deallocate(capacity: 1)

		var unsafeStatus: OpaquePointer? = nil
		let statusResult = git_status_list_new(&unsafeStatus, self.pointer, &options)
		guard statusResult == GIT_OK.rawValue, let unwrapStatusResult = unsafeStatus else {
			return Result.failure(NSError(gitError: statusResult, pointOfFailure: "git_status_list_new"))
		}

		let count = git_status_list_entrycount(unwrapStatusResult)

		for i in 0..<count {
			let s = git_status_byindex(unwrapStatusResult, i)
			if s?.pointee.status.rawValue == GIT_STATUS_CURRENT.rawValue {
				continue
			}
			var status: Status? = nil

			var headToIndex: DiffDelta? = nil
			var htoiStatus: Status? = nil
			var htoiOldFile: DiffFile? = nil
			var htoiNewFile: DiffFile? = nil

			var indexToWorkDir: DiffDelta? = nil
			var itowStatus: Status? = nil
			var itowOldFile: DiffFile? = nil
			var itowNewFile: DiffFile? = nil

			// Delta status
			if let statusValue = s?.pointee.status.rawValue {
				status = self.convertStatus(statusValue)
			}

			// Head To Index status and files
			if s?.pointee.head_to_index != nil {
				if let statusValue = s?.pointee.head_to_index.pointee.status.rawValue {
					htoiStatus = self.convertStatus(statusValue)
				}
				if let oldFile = s?.pointee.head_to_index.pointee.old_file {
					htoiOldFile = self.convertDiffFile(oldFile)
				}
				if let newFile = s?.pointee.head_to_index.pointee.new_file {
					htoiNewFile = self.convertDiffFile(newFile)
				}

				headToIndex = DiffDelta(status: htoiStatus,
				                        flags: s?.pointee.head_to_index.pointee.flags,
				                        oldFile: htoiOldFile,
				                        newFile: htoiNewFile)
			}

			// Index to Working Directory status and files
			if s?.pointee.index_to_workdir != nil {
				if let statusValue = s?.pointee.index_to_workdir.pointee.status.rawValue {
					itowStatus = self.convertStatus(statusValue)
				}
				if let oldFile = s?.pointee.index_to_workdir.pointee.old_file {
					itowOldFile = self.convertDiffFile(oldFile)
				}
				if let newFile = s?.pointee.index_to_workdir.pointee.new_file {
					itowNewFile = self.convertDiffFile(newFile)
				}

				indexToWorkDir = DiffDelta(status: itowStatus,
				                           flags: s?.pointee.index_to_workdir.pointee.flags,
				                           oldFile: itowOldFile,
				                           newFile: itowNewFile)
			}

			let statusEntry = StatusEntry(status: status, headToIndex: headToIndex, indexToWorkDir: indexToWorkDir)
			returnArray.append(statusEntry)
		}

		return Result.success(returnArray)
	}

	private func convertStatus(_ statusValue: UInt32) -> Status {
		var status: Status? = nil

		// Index status
		if (statusValue & GIT_STATUS_INDEX_NEW.rawValue) == GIT_STATUS_INDEX_NEW.rawValue {
			status = Status.indexNew
		} else if (statusValue & GIT_STATUS_INDEX_MODIFIED.rawValue) == GIT_STATUS_INDEX_MODIFIED.rawValue {
			status = Status.indexModified
		} else if (statusValue & GIT_STATUS_INDEX_DELETED.rawValue) == GIT_STATUS_INDEX_DELETED.rawValue {
			status = Status.indexDeleted
		} else if (statusValue & GIT_STATUS_INDEX_RENAMED.rawValue) == GIT_STATUS_INDEX_RENAMED.rawValue {
			status = Status.indexRenamed
		} else if (statusValue & GIT_STATUS_INDEX_TYPECHANGE.rawValue) == GIT_STATUS_INDEX_TYPECHANGE.rawValue {
			status = Status.indexTypeChange
		}

		// Worktree status
		if (statusValue & GIT_STATUS_WT_NEW.rawValue) == GIT_STATUS_WT_NEW.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeNew.rawValue)
		} else if (statusValue & GIT_STATUS_WT_MODIFIED.rawValue) == GIT_STATUS_WT_MODIFIED.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeModified.rawValue)
		} else if (statusValue & GIT_STATUS_WT_DELETED.rawValue) == GIT_STATUS_WT_DELETED.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeDeleted.rawValue)
		} else if (statusValue & GIT_STATUS_WT_RENAMED.rawValue) == GIT_STATUS_WT_RENAMED.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeRenamed.rawValue)
		} else if (statusValue & GIT_STATUS_WT_TYPECHANGE.rawValue) == GIT_STATUS_WT_TYPECHANGE.rawValue {
			status = Status(rawValue: status!.rawValue & Status.workTreeTypeChange.rawValue)
		}

		return status!
	}

	private func convertDiffFile(_ file: git_diff_file) -> DiffFile {
		let path = file.path
		let newFile = DiffFile(oid: OID(file.id),
		                          path: path.map(String.init(cString:))!,
		                          size: file.size,
		                          flags: file.flags)
		return newFile
	}
}

//
//  Repository.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2



/// A git repository.
public final class RepositoryOLD {

	// MARK: - Creating Repositories

	/// Create a new repository at the given URL.
	///
	/// URL - The URL of the repository.
	///
	/// Returns a `Result` with a `Repository` or an error.
	public class func create(at url: URL) -> Result<RepositoryOLD, Error> {
		var pointer: OpaquePointer? = nil
		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_init(&pointer, $0, 0)
		}

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_init"))
		}

		let repository = RepositoryOLD(pointer!)
		return Result.success(repository)
	}

	/// Load the repository at the given URL.
	///
	/// URL - The URL of the repository.
	///
	/// Returns a `Result` with a `Repository` or an error.
	public class func at(_ url: URL) -> Result<RepositoryOLD, Error> {
		var pointer: OpaquePointer? = nil
		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_open(&pointer, $0)
		}

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
		}

		let repository = RepositoryOLD(pointer!)
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
		//git_repository_free(pointer)
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
	private func withGitObject<T>(_ oid: OID, type: git_object_t,
	                              transform: (OpaquePointer) -> Result<T, Error>) -> Result<T, Error> {
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

	private func withGitObject<T>(_ oid: OID, type: git_object_t, transform: (OpaquePointer) -> T) -> Result<T, Error> {
		return withGitObject(oid, type: type) { Result.success(transform($0)) }
	}

	private func withGitObjects<T>(_ oids: [OID], type: git_object_t, transform: ([OpaquePointer]) -> Result<T, Error>) -> Result<T, Error> {
		var pointers = [OpaquePointer]()
		defer {
			for pointer in pointers {
				git_object_free(pointer)
			}
		}

		for oid in oids {
			var pointer: OpaquePointer? = nil
			var oid = oid.oid
			let result = git_object_lookup(&pointer, self.pointer, &oid, type)

			guard result == GIT_OK.rawValue else {
				return Result.failure(NSError(gitError: result, pointOfFailure: "git_object_lookup"))
			}

			pointers.append(pointer!)
		}

		return transform(pointers)
	}

	/// Loads the object with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns a `Blob`, `Commit`, `Tag`, or `Tree` if one exists, or an error.
	public func object(_ oid: OID) -> Result<ObjectType, Error> {
		return withGitObject(oid, type: GIT_OBJECT_ANY) { object in
			let type = git_object_type(object)
			if type == BlobOLD.type {
				return Result.success(BlobOLD(object))
			} else if type == CommitOLD.type {
				return Result.success(CommitOLD(object))
			} else if type == Tag.type {
				return Result.success(Tag(object))
			} else if type == Tree_Old.type {
				return Result.success(Tree_Old(object))
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
	
	public func blob(oid: OID) -> Result<Blob, Error> {
		var oid = oid.oid
		var blob_pointer: OpaquePointer? = nil
		
		return _result({ Blob(blob_pointer!) }, pointOfFailure: "git_object_lookup") {
			git_object_lookup(&blob_pointer, self.pointer, &oid, GIT_OBJECT_BLOB)
		}
	}

	/// Loads the blob with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns the blob if it exists, or an error.
	public func blobOld(_ oid: OID) -> Result<BlobOLD, Error> {
		return withGitObject(oid, type: GIT_OBJECT_BLOB) { BlobOLD($0) }
	}

	/// Loads the commit with the given OID.
	///
	/// oid - The OID of the commit to look up.
	///
	/// Returns the commit if it exists, or an error.
	public func commit(_ oid: OID) -> Result<CommitOLD, Error> {
		return withGitObject(oid, type: GIT_OBJECT_COMMIT) { CommitOLD($0) }
	}

	/// Loads the tag with the given OID.
	///
	/// oid - The OID of the tag to look up.
	///
	/// Returns the tag if it exists, or an error.
	public func tag(_ oid: OID) -> Result<Tag, Error> {
		return withGitObject(oid, type: GIT_OBJECT_TAG) { Tag($0) }
	}

	/// Loads the tree with the given OID.
	///
	/// oid - The OID of the tree to look up.
	///
	/// Returns the tree if it exists, or an error.
	public func tree(_ oid: OID) -> Result<Tree_Old, Error> {
		return withGitObject(oid, type: GIT_OBJECT_TREE) { Tree_Old($0) }
	}

	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func object<T>(from pointer: PointerTo<T>) -> Result<T, Error> {
		return withGitObject(pointer.oid, type: pointer.type) { T($0) }
	}

	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func object(from pointer: Pointer) -> Result<ObjectType, Error> {
		switch pointer {
		case let .blob(oid):
			return blobOld(oid).map { $0 as ObjectType }
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
	public func allRemotes() -> Result<[Remote_OLD], Error> {
		let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
		let result = git_remote_list(pointer, self.pointer)

		guard result == GIT_OK.rawValue else {
			pointer.deallocate()
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_remote_list"))
		}

		let strarray = pointer.pointee
		let remotes: [Result<Remote_OLD, Error>] = strarray.map {
			return self.remote(named: $0)
		}
		git_strarray_free(pointer)
		pointer.deallocate()

		return remotes.aggregateResult()
	}

	private func remoteLookup<A>(named name: String, _ callback: (Result<OpaquePointer, Error>) -> A) -> A {
		var pointer: OpaquePointer? = nil
		defer { git_remote_free(pointer) }

		let result = git_remote_lookup(&pointer, self.pointer, name)

		guard result == GIT_OK.rawValue else {
			return callback(.failure(NSError(gitError: result, pointOfFailure: "git_remote_lookup")))
		}

		return callback(.success(pointer!))
	}

	/// Load a remote from the repository.
	///
	/// name - The name of the remote.
	///
	/// Returns the remote if it exists, or an error.
	public func remote(named name: String) -> Result<Remote_OLD, Error> {
		return remoteLookup(named: name) { $0.map(Remote_OLD.init) }
	}

	/// Download new data and update tips
	public func fetch(_ remote: Remote_OLD) -> Result<(), Error> {
		return remoteLookup(named: remote.name) { remote in
			remote.flatMap { pointer in
				var opts = git_fetch_options()
				let resultInit = git_fetch_init_options(&opts, UInt32(GIT_FETCH_OPTIONS_VERSION))
				assert(resultInit == GIT_OK.rawValue)

				let result = git_remote_fetch(pointer, nil, &opts, nil)
				guard result == GIT_OK.rawValue else {
					let err = NSError(gitError: result, pointOfFailure: "git_remote_fetch")
					return .failure(err)
				}
				return .success(())
			}
		}
	}

	// MARK: - Reference Lookups

	/// Load all the references with the given prefix (e.g. "refs/heads/")
	public func references(withPrefix prefix: String) -> Result<[ReferenceType], Error> {
		let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
		let result = git_reference_list(pointer, self.pointer)

		guard result == GIT_OK.rawValue else {
			pointer.deallocate()
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
		pointer.deallocate()

		return references.aggregateResult()
	}

	/// Load the reference with the given long name (e.g. "refs/heads/master")
	///
	/// If the reference is a branch, a `Branch` will be returned. If the
	/// reference is a tag, a `TagReference` will be returned. Otherwise, a
	/// `Reference` will be returned.
	public func reference(named name: String) -> Result<ReferenceType, Error> {
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
	public func localBranches() -> Result<[BranchOLD], Error> {
		return references(withPrefix: "refs/heads/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! BranchOLD }
			}
	}

	/// Load and return a list of all remote branches.
	public func remoteBranches() -> Result<[BranchOLD], Error> {
		return references(withPrefix: "refs/remotes/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! BranchOLD }
			}
	}

	/// Load the local branch with the given name (e.g., "master").
	public func localBranch(named name: String) -> Result<BranchOLD, Error> {
		return reference(named: "refs/heads/" + name).map { $0 as! BranchOLD }
	}

	/// Load the remote branch with the given name (e.g., "origin/master").
	public func remoteBranch(named name: String) -> Result<BranchOLD, Error> {
		return reference(named: "refs/remotes/" + name).map { $0 as! BranchOLD }
	}

	/// Load and return a list of all the `TagReference`s.
	public func allTags() -> Result<[TagReference], Error> {
		return references(withPrefix: "refs/tags/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! TagReference }
			}
	}

	/// Load the tag with the given name (e.g., "tag-2").
	public func tag(named name: String) -> Result<TagReference, Error> {
		return reference(named: "refs/tags/" + name).map { $0 as! TagReference }
	}

	// MARK: - Working Directory

	/// Load the reference pointed at by HEAD.
	///
	/// When on a branch, this will return the current `Branch`.
	public func HEAD() -> Result<ReferenceType, Error> {
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
	public func setHEAD(_ oid: OID) -> Result<(), Error> {
		var oid = oid.oid
		let result = git_repository_set_head_detached(self.pointer, &oid)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head"))
		}
		return Result.success(())
	}

	/// Set HEAD to the given reference.
	///
	/// :param: reference The reference to set as HEAD.
	/// :returns: Returns a result with void or the error that occurred.
	public func setHEAD(_ reference: ReferenceType) -> Result<(), Error> {
		let result = git_repository_set_head(self.pointer, reference.longName)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head"))
		}
		return Result.success(())
	}

	/// Load all commits in the specified branch in topological & time order descending
	///
	/// :param: branch The branch to get all commits from
	/// :returns: Returns a result with array of branches or the error that occurred
	public func commits(in branch: BranchOLD) -> CommitIterator_OLD {
		let iterator = CommitIterator_OLD(repo: self, root: branch.oid.oid)
		return iterator
	}
	
	public func reset(path: String) -> Result<(), Error> {
		var paths = git_strarray(string: path)
		
		return HEAD().flatMap { self.commit($0.oid) }.flatMap { comit in
				
			let result = git_reset_default(self.pointer, comit.pointer, &paths)
			guard result == GIT_OK.rawValue else {
				return .failure(NSError(gitError: result, pointOfFailure: "git_reset_default"))
			}
				
			return .success(())
		}
	}

	/// Perform a commit with arbitrary numbers of parent commits.
	public func commit(
		tree treeOID: OID,
		parents: [CommitOLD],
		message: String,
		signature: Signature
	) -> Result<CommitOLD, Error> {
		// create commit signature
		return signature.makeUnsafeSignature().flatMap { signature in
			defer { git_signature_free(signature) }
			var tree: OpaquePointer? = nil
			var treeOIDCopy = treeOID.oid
			let lookupResult = git_tree_lookup(&tree, self.pointer, &treeOIDCopy)
			guard lookupResult == GIT_OK.rawValue else {
				let err = NSError(gitError: lookupResult, pointOfFailure: "git_tree_lookup")
				return .failure(err)
			}
			defer { git_tree_free(tree) }

			var msgBuf = git_buf()
			git_message_prettify(&msgBuf, message, 0, /* ascii for # */ 35)
			defer { git_buf_free(&msgBuf) }

			// libgit2 expects a C-like array of parent git_commit pointer
			var parentGitCommits: [OpaquePointer?] = []
			defer {
				for commit in parentGitCommits {
					git_commit_free(commit)
				}
			}
			for parentCommit in parents {
				var parent: OpaquePointer? = nil
				var oid = parentCommit.oid.oid
				let lookupResult = git_commit_lookup(&parent, self.pointer, &oid)
				guard lookupResult == GIT_OK.rawValue else {
					let err = NSError(gitError: lookupResult, pointOfFailure: "git_commit_lookup")
					return .failure(err)
				}
				parentGitCommits.append(parent!)
			}

			let parentsContiguous = ContiguousArray(parentGitCommits)
			return parentsContiguous.withUnsafeBufferPointer { unsafeBuffer in
				var commitOID = git_oid()
				let parentsPtr = UnsafeMutablePointer(mutating: unsafeBuffer.baseAddress)
				let result = git_commit_create(
					&commitOID,
					self.pointer,
					"HEAD",
					signature,
					signature,
					"UTF-8",
					msgBuf.ptr,
					tree,
					parents.count,
					parentsPtr
				)
				guard result == GIT_OK.rawValue else {
					return .failure(NSError(gitError: result, pointOfFailure: "git_commit_create"))
				}
				return commit(OID(commitOID))
			}
		}
	}

	/// Perform a commit of the staged files with the specified message and signature,
	/// assuming we are not doing a merge and using the current tip as the parent.
	public func commit(message: String, signature: Signature) -> Result<CommitOLD, Error> {
		return index().flatMap { index in
			var treeOID = git_oid() // out
			let treeResult = git_index_write_tree(&treeOID, index.pointer)
			guard treeResult == GIT_OK.rawValue else {
				let err = NSError(gitError: treeResult, pointOfFailure: "git_index_write_tree")
				return .failure(err)
			}
			var parentID = git_oid()
			let nameToIDResult = git_reference_name_to_id(&parentID, self.pointer, "HEAD")
			if nameToIDResult == GIT_OK.rawValue {
				return commit(OID(parentID)).flatMap { parentCommit in
					commit(tree: OID(treeOID), parents: [parentCommit], message: message, signature: signature)
				}
			}
			
			// if there are no parents: initial commit
			return commit(tree: OID(treeOID), parents: [], message: message, signature: signature)
		}
	}

	// MARK: - Diffs

	public func diff(for commit: CommitOLD) -> Result<Diff, Error> {
		guard !commit.parents.isEmpty else {
			// Initial commit in a repository
			return self.diff(from: nil, to: commit.oid)
		}

		var mergeDiff: OpaquePointer? = nil
		defer { git_object_free(mergeDiff) }
		for parent in commit.parents {
			let error = self.diff(from: parent.oid, to: commit.oid) {
				switch $0 {
				case .failure(let error):
					return error

				case .success(let newDiff):
					if mergeDiff == nil {
						mergeDiff = newDiff
					} else {
						let mergeResult = git_diff_merge(mergeDiff, newDiff)
						guard mergeResult == GIT_OK.rawValue else {
							return NSError(gitError: mergeResult, pointOfFailure: "git_diff_merge")
						}
					}
					return nil
				}
			}

			if error != nil {
				return Result<Diff, Error>.failure(error!)
			}
		}

		return .success(Diff(mergeDiff!))
	}

	private func diff(from oldCommitOid: OID?, to newCommitOid: OID?, transform: (Result<OpaquePointer, Error>) -> Error?) -> Error? {
		assert(oldCommitOid != nil || newCommitOid != nil, "It is an error to pass nil for both the oldOid and newOid")

		var oldTree: OpaquePointer? = nil
		defer { git_object_free(oldTree) }
		if let oid = oldCommitOid {
			switch unsafeTreeForCommitId(oid) {
			case .failure(let error):
				return transform(.failure(error))
			case .success(let value):
				oldTree = value
			}
		}

		var newTree: OpaquePointer? = nil
		defer { git_object_free(newTree) }
		if let oid = newCommitOid {
			switch unsafeTreeForCommitId(oid) {
			case .failure(let error):
				return transform(.failure(error))
			case .success(let value):
				newTree = value
			}
		}

		var diff: OpaquePointer? = nil
		let diffResult = git_diff_tree_to_tree(&diff,
		                                       self.pointer,
		                                       oldTree,
		                                       newTree,
		                                       nil)

		guard diffResult == GIT_OK.rawValue else {
			return transform(.failure(NSError(gitError: diffResult,
			                                  pointOfFailure: "git_diff_tree_to_tree")))
		}

		return transform(Result<OpaquePointer, Error>.success(diff!))
	}

	/// Memory safe
	private func diff(from oldCommitOid: OID?, to newCommitOid: OID?) -> Result<Diff, Error> {
		assert(oldCommitOid != nil || newCommitOid != nil, "It is an error to pass nil for both the oldOid and newOid")

		var oldTree: Tree_Old? = nil
		if let oldCommitOid = oldCommitOid {
			switch safeTreeForCommitId(oldCommitOid) {
			case .failure(let error):
				return .failure(error)
			case .success(let value):
				oldTree = value
			}
		}

		var newTree: Tree_Old? = nil
		if let newCommitOid = newCommitOid {
			switch safeTreeForCommitId(newCommitOid) {
			case .failure(let error):
				return .failure(error)
			case .success(let value):
				newTree = value
			}
		}

		if oldTree != nil && newTree != nil {
			return withGitObjects([oldTree!.oid, newTree!.oid], type: GIT_OBJECT_TREE) { objects in
				var diff: OpaquePointer? = nil
				let diffResult = git_diff_tree_to_tree(&diff,
				                                       self.pointer,
				                                       objects[0],
				                                       objects[1],
				                                       nil)
				return processTreeToTreeDiff(diffResult, diff: diff)
			}
		} else if let tree = oldTree {
			return withGitObject(tree.oid, type: GIT_OBJECT_TREE, transform: { tree in
				var diff: OpaquePointer? = nil
				let diffResult = git_diff_tree_to_tree(&diff,
				                                       self.pointer,
				                                       tree,
				                                       nil,
				                                       nil)
				return processTreeToTreeDiff(diffResult, diff: diff)
			})
		} else if let tree = newTree {
			return withGitObject(tree.oid, type: GIT_OBJECT_TREE, transform: { tree in
				var diff: OpaquePointer? = nil
				let diffResult = git_diff_tree_to_tree(&diff,
				                                       self.pointer,
				                                       nil,
				                                       tree,
				                                       nil)
				return processTreeToTreeDiff(diffResult, diff: diff)
			})
		}

		return .failure(NSError(gitError: -1, pointOfFailure: "diff(from: to:)"))
	}

	private func processTreeToTreeDiff(_ diffResult: Int32, diff: OpaquePointer?) -> Result<Diff, Error> {
		guard diffResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: diffResult,
			                        pointOfFailure: "git_diff_tree_to_tree"))
		}

		let diffObj = Diff(diff!)
		git_diff_free(diff)
		return .success(diffObj)
	}

	private func processDiffDeltas(_ diffResult: OpaquePointer) -> Result<[Diff.Delta], Error> {
		var returnDict = [Diff.Delta]()

		let count = git_diff_num_deltas(diffResult)

		for i in 0..<count {
			let delta = git_diff_get_delta(diffResult, i)
			let gitDiffDelta = Diff.Delta((delta?.pointee)!)

			returnDict.append(gitDiffDelta)
		}

		let result = Result<[Diff.Delta], Error>.success(returnDict)
		return result
	}

	private func safeTreeForCommitId(_ oid: OID) -> Result<Tree_Old, Error> {
		return withGitObject(oid, type: GIT_OBJECT_COMMIT) { commit in
			let treeId = git_commit_tree_id(commit)
			return tree(OID(treeId!.pointee))
		}
	}

	/// Caller responsible to free returned tree with git_object_free
	private func unsafeTreeForCommitId(_ oid: OID) -> Result<OpaquePointer, Error> {
		var commit: OpaquePointer? = nil
		var oid = oid.oid
		let commitResult = git_object_lookup(&commit, self.pointer, &oid, GIT_OBJECT_COMMIT)
		guard commitResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: commitResult, pointOfFailure: "git_object_lookup"))
		}

		var tree: OpaquePointer? = nil
		let treeId = git_commit_tree_id(commit)
		let treeResult = git_object_lookup(&tree, self.pointer, treeId, GIT_OBJECT_TREE)

		git_object_free(commit)

		guard treeResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: treeResult, pointOfFailure: "git_object_lookup"))
		}

		return Result<OpaquePointer, Error>.success(tree!)
	}

	// MARK: - Status

	public func status(options: StatusOptions = StatusOptions()) -> Result<[StatusEntry], Error> {
		var returnArray = [StatusEntry]()
		
		var git_options = options.git_options

		var unsafeStatus: OpaquePointer? = nil
		defer { git_status_list_free(unsafeStatus) }
		log(title: "SwiftGit2", msg: "git_status_list_new BEFORE")
		let statusResult = git_status_list_new(&unsafeStatus, self.pointer, &git_options)
		log(title: "SwiftGit2", msg: "git_status_list_new AFTER")
		guard statusResult == GIT_OK.rawValue, let unwrapStatusResult = unsafeStatus else {
			return .failure(NSError(gitError: statusResult, pointOfFailure: "git_status_list_new"))
		}

		let count = git_status_list_entrycount(unwrapStatusResult)

		for i in 0..<count {
			let s = git_status_byindex(unwrapStatusResult, i)
			if s?.pointee.status.rawValue == GIT_STATUS_CURRENT.rawValue {
				continue
			}

			let statusEntry = StatusEntry(from: s!.pointee)
			returnArray.append(statusEntry)
		}
		return .success(returnArray)
	}

	// MARK: - Validity/Existence Check

	/// - returns: `.success(true)` iff there is a git repository at `url`,
	///   `.success(false)` if there isn't,
	///   and a `.failure` if there's been an error.
	public static func isValid(url: URL) -> Result<Bool, Error> {
		var pointer: OpaquePointer?

		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_open_ext(&pointer, $0, GIT_REPOSITORY_OPEN_NO_SEARCH.rawValue, nil)
		}

		switch result {
		case GIT_ENOTFOUND.rawValue:
			return .success(false)
		case GIT_OK.rawValue:
			return .success(true)
		default:
			return .failure(NSError(gitError: result, pointOfFailure: "git_repository_open_ext"))
		}
	}
}

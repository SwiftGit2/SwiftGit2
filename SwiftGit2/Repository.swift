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
			buffer.deallocate()
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
	pointer.deallocate()

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

	pointer.deallocate()

	options.callbacks.payload = credentials.toPointer()
	options.callbacks.credentials = credentialsCallback

	return options
}

private func pushOptions(credentials: Credentials) -> git_push_options {
	let pointer = UnsafeMutablePointer<git_push_options>.allocate(capacity: 1)
	git_push_init_options(pointer, UInt32(GIT_PUSH_OPTIONS_VERSION))
	
	var options = pointer.move()
	
	pointer.deallocate()
	
	options.callbacks.payload = credentials.toPointer()
	options.callbacks.credentials = credentialsCallback
	
	return options
}

private func cloneOptions(bare: Bool = false, localClone: Bool = false, fetchOptions: git_fetch_options? = nil,
                          checkoutOptions: git_checkout_options? = nil) -> git_clone_options {
	let pointer = UnsafeMutablePointer<git_clone_options>.allocate(capacity: 1)
	git_clone_init_options(pointer, UInt32(GIT_CLONE_OPTIONS_VERSION))

	var options = pointer.move()

	pointer.deallocate()

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

	private func withGitObjects<T>(_ oids: [OID], type: git_otype, transform: ([OpaquePointer]) -> Result<T, NSError>) -> Result<T, NSError> {
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
			pointer.deallocate()
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_remote_list"))
		}

		let strarray = pointer.pointee
		let remotes: [Result<Remote, NSError>] = strarray.map {
			return self.remote(named: $0)
		}
		git_strarray_free(pointer)
		pointer.deallocate()

		let error = remotes.reduce(nil) { $0 == nil ? $0 : $1.error }
		if let error = error {
			return Result.failure(error)
		}
		return Result.success(remotes.map { $0.value! })
	}

	private func remoteLookup<A>(named name: String, _ callback: (Result<OpaquePointer, NSError>) -> A) -> A {
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
	public func remote(named name: String) -> Result<Remote, NSError> {
		return remoteLookup(named: name) { $0.map(Remote.init) }
	}

	/// Download new data and update tips
	public func fetch(_ remote: Remote, credentials: Credentials = .default) -> Result<(), NSError> {
		return remoteLookup(named: remote.name) { remote in
			remote.flatMap { pointer in
				var opts: git_fetch_options
				if credentials != Credentials.default {
					opts = fetchOptions(credentials: credentials)
				} else {
					opts = git_fetch_options()
					let resultInit = git_fetch_init_options(&opts, UInt32(GIT_FETCH_OPTIONS_VERSION))
					assert(resultInit == GIT_OK.rawValue)
				}
				let result = git_remote_fetch(pointer, nil, &opts, nil)
				guard result == GIT_OK.rawValue else {
					let err = NSError(gitError: result, pointOfFailure: "git_remote_fetch")
					return .failure(err)
				}
				return .success(())
			}
		}
	}

	// MARK: - Pushing / Pulling

	/// Push branch to the specified remote.
	/// If branch is a local branch, will try to push to the corresponding remote branch with the same name.
	public func push(remote remoteSwift: Remote, branch: Branch, credentials: Credentials? = nil) -> Result<(), NSError> {
		return remoteLookup(named: remoteSwift.name) { result in
			result.flatMap { remote in
				let connectResult: Int32
				if let credentials = credentials {
					var callbacks = git_remote_callbacks()
					let initCallbacksResult = git_remote_init_callbacks(&callbacks, UInt32(GIT_REMOTE_CALLBACKS_VERSION))
					guard initCallbacksResult == GIT_OK.rawValue else {
						return Result.failure(NSError(gitError: initCallbacksResult, pointOfFailure: "git_remote_init_callbacks"))
					}
					callbacks.payload = credentials.toPointer()
					callbacks.credentials = credentialsCallback
					connectResult = git_remote_connect(remote, GIT_DIRECTION_PUSH, &callbacks, nil)
				} else {
					connectResult = git_remote_connect(remote, GIT_DIRECTION_PUSH, nil, nil)
				}
				guard connectResult == GIT_OK.rawValue else {
					return Result.failure(NSError(gitError: connectResult, pointOfFailure: "git_remote_connect"))
				}
				var options: git_push_options
				if let credentials = credentials {
					options = pushOptions(credentials: credentials)
				} else {
					options = git_push_options()
					git_push_init_options(&options, UInt32(GIT_PUSH_OPTIONS_VERSION))
				}
				// lookup refspec
				var refspecArray = git_strarray()
				let getRefspecsResult = git_remote_get_push_refspecs(&refspecArray, remote)
				guard getRefspecsResult == GIT_OK.rawValue else {
					return Result.failure(NSError(gitError: getRefspecsResult, pointOfFailure: "git_remote_get_push_refspecs"))
				}
				defer { git_strarray_free(&refspecArray) }
				guard let refspec = (refspecArray.filter { $0 == "\(branch.longName):\(branch.longName)" }).first else {
					return Result.failure(NSError(domain: "SwiftGit2", code: -1, userInfo: nil))
				}
				let ptrRefspec = UnsafeMutablePointer<Int8>(mutating: (refspec as NSString).utf8String)
				var selectedRefspecs = [ptrRefspec]
				var selectedRefspecArray = git_strarray(strings: &selectedRefspecs, count: 1)
				// do the push
				let uploadResult = git_remote_upload(remote, &selectedRefspecArray, &options)
				guard uploadResult == GIT_OK.rawValue else {
					return Result.failure(NSError(gitError: uploadResult, pointOfFailure: "git_remote_upload"))
				}
				return .success(())
			}
		}
	}

	public enum ConflictResolutionDecision {
		case ours
		case theirs
		case merge(Data)
	}

	/// Takes in "our" side and "their" side of the file respectively, and returns a decision
	public typealias ConflictResolver = (Data, Data) -> ConflictResolutionDecision

	/// Pulls from the remote and updates our local branch.
	public func pull(
		remote: Remote,
		branch: Branch,
		signatureMaker: () -> Signature,
		credentials: Credentials = .default,
		conflictResolver: ConflictResolver,
		progress: CheckoutProgressBlock? = nil
		) -> Result<Void, NSError> {
		// first initiate a fetch
		return fetch(remote, credentials: credentials).flatMap { _ in
			let localBranchResult = self.localBranch(named: branch.name)
			guard case .success(let localBranch) = localBranchResult else {
				return localBranchResult.map { _ in () }
			}
			// determine if we need to perform a merge
			// if local commit is the same as remote commit, no need
			return branch.getTrackingBranch(repo: self).flatMap { trackingBranch in
				// determine if the local branch can be fast-forwarded
				guard localBranch.oid != trackingBranch.oid else {
					return .success(())
				}
				// determine if a clean merge can be performed
				var annotatedCommit: OpaquePointer? = nil
				var oid = trackingBranch.oid.oid
				let lookupResult = git_annotated_commit_lookup(&annotatedCommit, self.pointer, &oid)
				guard lookupResult == GIT_OK.rawValue else {
					return Result.failure(NSError(gitError: lookupResult, pointOfFailure: "git_annotated_commit_lookup"))
				}
				defer { git_annotated_commit_free(annotatedCommit) }
				var analysis = GIT_MERGE_ANALYSIS_NONE
				var preference = GIT_MERGE_PREFERENCE_NONE
				let analysisResult = git_merge_analysis(&analysis, &preference, self.pointer, &annotatedCommit, 1)
				guard analysisResult == GIT_OK.rawValue else {
					return Result.failure(NSError(gitError: analysisResult, pointOfFailure: "git_merge_analysis"))
				}
				if analysis.rawValue & GIT_MERGE_ANALYSIS_UP_TO_DATE.rawValue != 0 {
					// nothing needs to be done
					return .success(())
				} else if analysis.rawValue & GIT_MERGE_ANALYSIS_UNBORN.rawValue != 0
					|| analysis.rawValue & GIT_MERGE_ANALYSIS_FASTFORWARD.rawValue != 0 {
					// fast-forward local branch
					let message = "merge \(remote.name)/\(trackingBranch.name): Fast-forward"
					return localBranch.referenceByUpdatingTarget(
						repo: self,
						newTarget: trackingBranch.oid,
						message: message
					).flatMap { newRef in
						self.checkout(newRef.oid, strategy: CheckoutStrategy.Force, progress: progress)
					}
				} else if analysis.rawValue & GIT_MERGE_ANALYSIS_NORMAL.rawValue != 0 {
					// normal merge
					return unsafeTreeForCommitId(localBranch.commit.oid).flatMap { localTree in
						defer { git_tree_free(localTree) }
						return unsafeTreeForCommitId(trackingBranch.commit.oid).flatMap { remoteTree in
							defer { git_tree_free(remoteTree) }
							// check conflicts
							var index: OpaquePointer? = nil
							var baseOID = git_oid()
							var localOID = localBranch.commit.oid.oid
							var remoteOID = trackingBranch.commit.oid.oid
							let findMergeBaseResult = git_merge_base(&baseOID, self.pointer, &localOID, &remoteOID)
							var baseTree: OpaquePointer? = nil
							if findMergeBaseResult == GIT_OK.rawValue {
								let result = commit(OID(baseOID)).flatMap { baseCommit -> Result<(), NSError> in
									unsafeTreeForCommitId(baseCommit.oid).flatMap { baseTreeUnsafe -> Result<(), NSError> in
										baseTree = baseTreeUnsafe
										return .success(())
									}
								}
								if case .failure = result {
									return result
								}
							}
							let mergeTreeResult = git_merge_trees(
								&index,
								self.pointer,
								baseTree,
								localTree,
								remoteTree,
								nil
							)
							if let baseTree = baseTree {
								defer { git_tree_free(baseTree) }
							}
							guard mergeTreeResult == GIT_OK.rawValue else {
								return Result.failure(NSError(gitError: mergeTreeResult, pointOfFailure: "git_merge_trees"))
							}
							// if a clean merge cannot be performed,
							// call the user-supplied conflict resolver
							if git_index_has_conflicts(index!) > 0 {
								fatalError()
							}
							var treeOID = git_oid()
							let writeTreeResult = git_index_write_tree_to(&treeOID, index!, self.pointer)
							guard writeTreeResult == GIT_OK.rawValue else {
								return Result.failure(NSError(gitError: writeTreeResult, pointOfFailure: "git_index_write_tree"))
							}
							// create merge commit
							var parents: [Commit] = []
							for p in [commit(localBranch.commit.oid), commit(trackingBranch.commit.oid)] {
								if case .failure = p {
									return p.map { _ in () }
								} else if case .success(let c) = p {
									parents.append(c)
								}
							}
							let message = "Merge branch '\(localBranch.shortName ?? localBranch.name)'"
							return commit(
								tree: treeOID,
								parents: parents,
								message: message,
								signature: signatureMaker()
							).flatMap { commit in
								checkout(commit.oid, strategy: CheckoutStrategy.Force, progress: progress)
							}
						}
					}
				} else {
					return Result.failure(NSError(gitError: analysisResult, pointOfFailure: "decoding merge result"))
				}
			}
		}
	}

	// MARK: - Reference Lookups

	/// Load all the references with the given prefix (e.g. "refs/heads/")
	public func references(withPrefix prefix: String) -> Result<[ReferenceType], NSError> {
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
		return Result.success(())
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
		return Result.success(())
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

		return Result.success(())
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

	/// Get the index for the repo. The caller is responsible for freeing the index.
	func unsafeIndex() -> Result<OpaquePointer, NSError> {
		var index: OpaquePointer? = nil
		let result = git_repository_index(&index, self.pointer)
		guard result == GIT_OK.rawValue && index != nil else {
			let err = NSError(gitError: result, pointOfFailure: "git_repository_index")
			return .failure(err)
		}
		return .success(index!)
	}

	/// Stage the file(s) under the specified path.
	public func add(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		return unsafeIndex().flatMap { index in
			defer { git_index_free(index) }
			let addResult = git_index_add_all(index, &paths, 0, nil, nil)
			guard addResult == GIT_OK.rawValue else {
				return .failure(NSError(gitError: addResult, pointOfFailure: "git_index_add_all"))
			}
			// write index to disk
			let writeResult = git_index_write(index)
			guard writeResult == GIT_OK.rawValue else {
				return .failure(NSError(gitError: writeResult, pointOfFailure: "git_index_write"))
			}
			return .success(())
		}
	}

	/// Perform a commit with arbitrary numbers of parent commits.
	public func commit(
		tree treeOID: git_oid,
		parents: [Commit],
		message: String,
		signature: Signature
	) -> Result<Commit, NSError> {
		// create commit signature
		return signature.unsafeSignature.flatMap { signature in
			defer { git_signature_free(signature) }
			var tree: OpaquePointer? = nil
			var treeOIDCopy = treeOID
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
	public func commit(message: String, signature: Signature) -> Result<Commit, NSError> {
		return unsafeIndex().flatMap { index in
			defer { git_index_free(index) }
			var treeOID = git_oid()
			let treeResult = git_index_write_tree(&treeOID, index)
			guard treeResult == GIT_OK.rawValue else {
				let err = NSError(gitError: treeResult, pointOfFailure: "git_index_write_tree")
				return .failure(err)
			}
			var parentID = git_oid()
			let nameToIDResult = git_reference_name_to_id(&parentID, self.pointer, "HEAD")
			guard nameToIDResult == GIT_OK.rawValue else {
				return .failure(NSError(gitError: nameToIDResult, pointOfFailure: "git_reference_name_to_id"))
			}
			return commit(OID(parentID)).flatMap { parentCommit in
				commit(tree: treeOID, parents: [parentCommit], message: message, signature: signature)
			}
		}
	}

	// MARK: - Diffs

	public func diff(for commit: Commit) -> Result<Diff, NSError> {
		typealias Delta = Diff.Delta

		guard !commit.parents.isEmpty else {
			// Initial commit in a repository
			return self.diff(from: nil, to: commit.oid)
		}

		var mergeDiff: OpaquePointer? = nil
		defer { git_object_free(mergeDiff) }
		for parent in commit.parents {
			let error = self.diff(from: parent.oid, to: commit.oid) { (diff: Result<OpaquePointer, NSError>) -> NSError? in
				guard diff.error == nil else {
					return diff.error!
				}

				if mergeDiff == nil {
					mergeDiff = diff.value!
				} else {
					let mergeResult = git_diff_merge(mergeDiff, diff.value)
					guard mergeResult == GIT_OK.rawValue else {
						return NSError(gitError: mergeResult, pointOfFailure: "git_diff_merge")
					}
				}
				return nil
			}

			if error != nil {
				return Result<Diff, NSError>.failure(error!)
			}
		}

		return .success(Diff(mergeDiff!))
	}

	private func diff(from oldCommitOid: OID?, to newCommitOid: OID?, transform: (Result<OpaquePointer, NSError>) -> NSError?) -> NSError? {
		assert(oldCommitOid != nil || newCommitOid != nil, "It is an error to pass nil for both the oldOid and newOid")

		var oldTree: OpaquePointer? = nil
		defer { git_object_free(oldTree) }
		if let oid = oldCommitOid {
			let result = unsafeTreeForCommitId(oid)
			guard result.error == nil else {
				return transform(Result.failure(result.error!))
			}

			oldTree = result.value
		}

		var newTree: OpaquePointer? = nil
		defer { git_object_free(newTree) }
		if let oid = newCommitOid {
			let result = unsafeTreeForCommitId(oid)
			guard result.error == nil else {
				return transform(Result.failure(result.error!))
			}

			newTree = result.value
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

		return transform(Result<OpaquePointer, NSError>.success(diff!))
	}

	/// Memory safe
	private func diff(from oldCommitOid: OID?, to newCommitOid: OID?) -> Result<Diff, NSError> {
		assert(oldCommitOid != nil || newCommitOid != nil, "It is an error to pass nil for both the oldOid and newOid")

		var oldTree: Tree? = nil
		if oldCommitOid != nil {
			let result = safeTreeForCommitId(oldCommitOid!)
			guard result.error == nil else {
				return Result<Diff, NSError>.failure(result.error!)
			}
			oldTree = result.value
		}

		var newTree: Tree? = nil
		if newCommitOid != nil {
			let result = self.safeTreeForCommitId(newCommitOid!)
			guard result.error == nil else {
				return Result<Diff, NSError>.failure(result.error!)
			}
			newTree = result.value!
		}

		if oldTree != nil && newTree != nil {
			return withGitObjects([oldTree!.oid, newTree!.oid], type: GIT_OBJ_TREE) { objects in
				var diff: OpaquePointer? = nil
				let diffResult = git_diff_tree_to_tree(&diff,
																							 self.pointer,
																							 objects[0],
																							 objects[1],
																							 nil)
				return processTreeToTreeDiff(diffResult, diff: diff)
			}
		} else if let tree = oldTree {
			return withGitObject(tree.oid, type: GIT_OBJ_TREE, transform: { tree in
				var diff: OpaquePointer? = nil
				let diffResult = git_diff_tree_to_tree(&diff,
																							 self.pointer,
																							 tree,
																							 nil,
																							 nil)
				return processTreeToTreeDiff(diffResult, diff: diff)
			})
		} else if let tree = newTree {
			return withGitObject(tree.oid, type: GIT_OBJ_TREE, transform: { tree in
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

	private func processTreeToTreeDiff(_ diffResult: Int32, diff: OpaquePointer?) -> Result<Diff, NSError> {
		guard diffResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: diffResult,
															pointOfFailure: "git_diff_tree_to_tree"))
		}

		let diffObj = Diff(diff!)
		git_diff_free(diff)
		return .success(diffObj)
	}

	private func processDiffDeltas(_ diffResult: OpaquePointer) -> Result<[Diff.Delta], NSError> {
		typealias Delta = Diff.Delta
		var returnDict = [Delta]()

		let count = git_diff_num_deltas(diffResult)

		for i in 0..<count {
			let delta = git_diff_get_delta(diffResult, i)
			let gitDiffDelta = Diff.Delta((delta?.pointee)!)

			returnDict.append(gitDiffDelta)
		}

		let result = Result<[Diff.Delta], NSError>.success(returnDict)
		return result
	}

	private func safeTreeForCommitId(_ oid: OID) -> Result<Tree, NSError> {
		return withGitObject(oid, type: GIT_OBJ_COMMIT) { commit in
			let treeId = git_commit_tree_id(commit)
			let tree = self.tree(OID(treeId!.pointee))
			guard tree.error == nil else {
				return .failure(tree.error!)
			}
			return tree
		}
	}

	/// Caller responsible to free returned tree with git_object_free
	private func unsafeTreeForCommitId(_ oid: OID) -> Result<OpaquePointer, NSError> {
		var commit: OpaquePointer? = nil
		var oid = oid.oid
		let commitResult = git_object_lookup(&commit, self.pointer, &oid, GIT_OBJ_COMMIT)
		guard commitResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: commitResult, pointOfFailure: "git_object_lookup"))
		}

		var tree: OpaquePointer? = nil
		let treeId = git_commit_tree_id(commit)
		let treeResult = git_object_lookup(&tree, self.pointer, treeId, GIT_OBJ_TREE)

		git_object_free(commit)

		guard treeResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: treeResult, pointOfFailure: "git_object_lookup"))
		}

		return Result<OpaquePointer, NSError>.success(tree!)
	}

	// MARK: - Status

	public func status() -> Result<[StatusEntry], NSError> {
		var returnArray = [StatusEntry]()

		// Do this because GIT_STATUS_OPTIONS_INIT is unavailable in swift
		let pointer = UnsafeMutablePointer<git_status_options>.allocate(capacity: 1)
		let optionsResult = git_status_init_options(pointer, UInt32(GIT_STATUS_OPTIONS_VERSION))
		guard optionsResult == GIT_OK.rawValue else {
			return .failure(NSError(gitError: optionsResult, pointOfFailure: "git_status_init_options"))
		}
		var options = pointer.move()
		pointer.deallocate()

		var unsafeStatus: OpaquePointer? = nil
		defer { git_status_list_free(unsafeStatus) }
		let statusResult = git_status_list_new(&unsafeStatus, self.pointer, &options)
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
}

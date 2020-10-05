//
//  RepositoryInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Repository : InstanceProtocol {
	public var pointer: OpaquePointer
	
	public var directoryURL: URL? {
		let path = git_repository_workdir(self.pointer)
		
		return path.map({ URL(fileURLWithPath: String(validatingUTF8: $0)!, isDirectory: true) })
	}
	
	required public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit { git_repository_free(pointer) }
}

extension Repository {
	public func headParentCommit() -> Result<Commit, NSError> {
		var parentID = git_oid() //out
		
		return _result((), pointOfFailure: "git_reference_name_to_id") {
			git_reference_name_to_id(&parentID, self.pointer, "HEAD")
		}
		.flatMap { _ in
			self.instanciate(OID(parentID)) as Result<Commit, NSError>
		}
	}
	
	
	public func createBranch(from commit: Commit, withName newName: String, overwriteExisting: Bool = false) -> Result<Reference, NSError> {
		let force: Int32 = overwriteExisting ? 0 : 1
		
		var referenceToBranch : OpaquePointer? = nil
		
		return _result( { Reference(referenceToBranch!) }, pointOfFailure: "git_branch_create") {
			newName.withCString { new_name in
				git_branch_create(&referenceToBranch, self.pointer, new_name, commit.pointer, force);
			}
		}
	}
	
	public func commit(message: String, signature: Signature) -> Result<Commit, NSError> {
		return index().flatMap { index in
			return Duo((index,self)).commit(message: message, signature: signature)
		}
	}


	

	
	public func mergeCommits(commitFrom: Commit, commitInto: Commit ) -> Result<Index, NSError> {
		var mrgOptions = mergeOptions()
		
		var rezPointer : OpaquePointer? = nil
		
		return _result( { Index(rezPointer!) } , pointOfFailure: "git_merge_commits") {
			git_merge_commits(&rezPointer, self.pointer , commitFrom.pointer, commitInto.pointer, &mrgOptions)
		}
	}
	
	public func remoteRepo(named name: String ) -> Result<Remote, NSError> {
		return remoteLookup(named: name) { $0.map(Remote.init) }
	}
	
	public func remoteLookup<A>(named name: String, _ callback: (Result<OpaquePointer, NSError>) -> A) -> A {
		var pointer: OpaquePointer? = nil

		let result = git_remote_lookup(&pointer, self.pointer, name)

		//TODO: Can be optimized
		guard result == GIT_OK.rawValue else {
			return callback(.failure(NSError(gitError: result, pointOfFailure: "git_remote_lookup")))
		}

		return callback(.success(pointer!))
	}
}

public extension Repository {
	class func at(url: URL) -> Result<Repository, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Repository(pointer!) }, pointOfFailure: "git_repository_open") {
			url.withUnsafeFileSystemRepresentation {
				git_repository_open(&pointer, $0)
			}
		}
	}
	
	class func create(at url: URL) -> Result<Repository, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Repository(pointer!) }, pointOfFailure: "git_repository_init") {
			url.withUnsafeFileSystemRepresentation {
				git_repository_init(&pointer, $0, 1)
			}
		}
	}
}


// index
public extension Repository {
	func reset(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		
		return HEAD()
			.flatMap { self.instanciate($0.oid) as Result<Commit, NSError> }
			.flatMap { commit in
				_result((), pointOfFailure: "git_reset_default") {
					git_reset_default(self.pointer, commit.pointer, &paths)
				}
		}
	}
}


// STATIC funcs
public extension Repository {
	/// Clone the repository from a given URL.
	///
	/// remoteURL            The URL of the remote repository
	/// localURL                The URL to clone the remote repository into
	/// localClone              Will not bypass the git-aware transport, even if remote is local.
	/// bare                        Clone remote as a bare repository.
	/// credentials              Credentials to be used when connecting to the remote.
	/// checkoutStrategy    The checkout strategy to use, if being checked out.
	/// checkoutProgress   A block that's called with the progress of the checkout.
	///
	/// Returns a `Result` with a `Repository` or an error.
	static func clone(from remoteURL: URL, to localURL: URL, isLocalClone: Bool = false, bare: Bool = false,
							credentials: Credentials = .default, checkoutStrategy: CheckoutStrategy = .Safe,
							checkoutProgress: CheckoutProgressBlock? = nil) -> Result<Repository, NSError> {
			var options = cloneOptions(
				bare: bare,
				localClone: isLocalClone,
				fetchOptions: fetchOptions(credentials: credentials),
				checkoutOptions: checkoutOptions(strategy: checkoutStrategy, progress: checkoutProgress))

			var pointer: OpaquePointer? = nil
			let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString
			
			let result = localURL.withUnsafeFileSystemRepresentation { localPath in
				git_clone(&pointer, remoteURLString, localPath, &options)
			}

			//TODO: can be optimized
			guard result == GIT_OK.rawValue else {
				return Result.failure(NSError(gitError: result, pointOfFailure: "git_clone"))
			}

			let repository = Repository(pointer!)
			return Result.success(repository)
	}
}











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// HELPERS
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


extension Array {
	func aggregateResult<Value, Error>() -> Result<[Value], Error> where Element == Result<Value, Error> {
		var values: [Value] = []
		for result in self {
			switch result {
			case .success(let value):
				values.append(value)
			case .failure(let error):
				return .failure(error)
			}
		}
		return .success(values)
	}
}

fileprivate func fetchOptions(credentials: Credentials) -> git_fetch_options {
	let pointer = UnsafeMutablePointer<git_fetch_options>.allocate(capacity: 1)
	git_fetch_init_options(pointer, UInt32(GIT_FETCH_OPTIONS_VERSION))

	var options = pointer.move()

	pointer.deallocate()

	options.callbacks.payload = credentials.toPointer()
	options.callbacks.credentials = credentialsCallback

	return options
}

fileprivate func cloneOptions(bare: Bool = false, localClone: Bool = false, fetchOptions: git_fetch_options? = nil,
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

/// Helper function for initializing libgit2 git_checkout_options.
///
/// :param: strategy The strategy to be used when checking out the repo, see CheckoutStrategy
/// :param: progress A block that's called with the progress of the checkout.
/// :returns: Returns a git_checkout_options struct with the progress members set.
fileprivate func checkoutOptions(strategy: CheckoutStrategy,
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

/// Helper function used as the libgit2 progress callback in git_checkout_options.
/// This is a function with a type signature of git_checkout_progress_cb.
fileprivate func checkoutProgressCallback(path: UnsafePointer<Int8>?, completedSteps: Int, totalSteps: Int,
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



fileprivate func mergeOptions( mergeFlags: git_merge_flag_t? = nil,
							   fileFlags: git_merge_file_flag_t? = nil,
							   renameTheshold: Int = 50 ) -> git_merge_options {

	let pointer = UnsafeMutablePointer<git_merge_options>.allocate(capacity: 1)

	git_merge_init_options(pointer, UInt32(GIT_MERGE_OPTIONS_VERSION))

	var options = pointer.move()

	pointer.deallocate()

	if let mergeFlags = mergeFlags {
		options.flags = mergeFlags.rawValue
	}

	if let fileFlags = fileFlags {
		options.file_flags	= fileFlags.rawValue
	}

	options.rename_threshold = UInt32( renameTheshold )

	//options.

	return options
}

//
//  RepositoryInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Repository : InstanceProtocol {
	public var pointer: OpaquePointer
	
	public var directoryURL: Result<URL, Error> {
		if let pathPointer = git_repository_workdir(self.pointer) {
			return .success( URL(fileURLWithPath: String(cString: pathPointer) , isDirectory: true) )
		}
		
		return .failure(RepositoryError.FailedToGetRepoUrl as Error)
	}
	
	required public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_repository_free(pointer)
	}
}

//Remotes
extension Repository {
	public func getRemoteFirst() -> Result<Remote, Error> {
		return getRemotesNames()
			.flatMap{ arr -> Result<Remote, Error> in
				if let first = arr.first {
					return self.remoteRepo(named: first, remoteType: .ForceHttps)
				}
				return .failure(WTF("can't get RemotesNames") )
			}
	}
	
	public func getAllRemotes() -> Result<[Remote], Error> {
		return getRemotesNames()
			.flatMap{ $0.map({ self.remoteRepo(named: $0, remoteType: .ForceHttps) }).aggregateResult() }
	}
	
	private func getRemotesNames() -> Result<[String], Error> {
		var strarray = git_strarray()

		return _result( { strarray.map{ $0 } } , pointOfFailure: "git_remote_list") {
			git_remote_list(&strarray, self.pointer)
		}
	}
}

extension Repository {
	public func headCommit() -> Result<Commit, Error> {
		var oid = git_oid()
		
		return _result( { oid }, pointOfFailure: "git_reference_name_to_id") {
			git_reference_name_to_id(&oid, self.pointer, "HEAD")
		}
		.flatMap { instanciate(OID($0)) }
	}
	
	
	public func createBranch(from commit: Commit, withName newName: String, overwriteExisting: Bool = false) -> Result<Reference, Error> {
		let force: Int32 = overwriteExisting ? 0 : 1
		
		var referenceToBranch : OpaquePointer? = nil
		
		return _result( { Reference(referenceToBranch!) }, pointOfFailure: "git_branch_create") {
			newName.withCString { new_name in
				git_branch_create(&referenceToBranch, self.pointer, new_name, commit.pointer, force);
			}
		}
	}
	
	public func commit(message: String, signature: Signature) -> Result<Commit, Error> {
		return index()
			.flatMap { index in Duo((index,self)).commit(message: message, signature: signature) }
	}
	
	public func mergeCommits(commitFrom: Commit, commitInto: Commit ) -> Result<Index, Error> {
		var options = MergeOptions()
		var indexPointer : OpaquePointer? = nil
		
		return _result( { Index(indexPointer!) } , pointOfFailure: "git_merge_commits") {
			git_merge_commits(&indexPointer, self.pointer , commitFrom.pointer, commitInto.pointer, &options.merge_options)
		}
	}
	
	public func remoteRepo(named name: String, remoteType: RemoteType) -> Result<Remote, Error> {
		return remoteLookup(named: name) { $0.map{ Remote($0, remoteType: remoteType) } }
	}
	
	public func remoteLookup<A>(named name: String, _ callback: (Result<OpaquePointer, Error>) -> A) -> A {
		var pointer: OpaquePointer? = nil
		
		let result = _result( () , pointOfFailure: "git_remote_lookup") {
			git_remote_lookup(&pointer, self.pointer, name)
		}.map{ pointer! }
		
		return callback(result)
	}
}

public extension Repository {
	class func at(url: URL) -> Result<Repository, Error> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Repository(pointer!) }, pointOfFailure: "git_repository_open") {
			url.withUnsafeFileSystemRepresentation {
				git_repository_open(&pointer, $0)
			}
		}
	}
	
	class func create(at url: URL) -> Result<Repository, Error> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Repository(pointer!) }, pointOfFailure: "git_repository_init") {
			url.path.withCString { path in
				git_repository_init(&pointer, path, 1)
			}
		}
	}
}


// index
public extension Repository {
	func reset(path: String) -> Result<(), Error> {
		var paths = git_strarray(string: path)
				
		return HEAD()
			.flatMap { self.instanciate($0.oid) as Result<Commit, Error> }
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
							credentials: Credentials_OLD = .default, checkoutStrategy: CheckoutStrategy = .Safe,
							checkoutProgress: CheckoutProgressBlock? = nil) -> Result<Repository, Error> {
		

		var pointer: OpaquePointer? = nil
		var options = cloneOptions(
			bare: bare,
			localClone: isLocalClone,
			fetchOptions: FetchOptions(callbacks: RemoteCallbacks()).fetch_options,
			checkoutOptions: checkoutOptions(strategy: checkoutStrategy, progress: checkoutProgress))

		let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString

		
		return _result( { Repository(pointer!) } , pointOfFailure: "git_clone") {
			
			return localURL.withUnsafeFileSystemRepresentation { localPath in
				return git_clone(&pointer, remoteURLString, localPath, &options)
			}
		}
	}
	
	static func clone(from remoteURL: URL, to localURL: URL, options: CloneOptions = CloneOptions()) -> Result<Repository, Error> {
		var pointer: OpaquePointer? = nil
		let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString
		
		var options = options.clone_options
		
		return _result( { Repository(pointer!) } , pointOfFailure: "git_clone") {
			return localURL.withUnsafeFileSystemRepresentation { localPath in
				return git_clone(&pointer, remoteURLString, localPath, &options)
			}
		}
	}
	
}











/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// HELPERS
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


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

////////////////////////////////////////////////////////////////////
///ERRORS
////////////////////////////////////////////////////////////////////

enum RepositoryError: Error {
	case FailedToGetRepoUrl
}

extension RepositoryError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .FailedToGetRepoUrl:
			return "FailedToGetRepoUrl. Url is nil?"
		}
	}
}

public enum RemoteType {
	case Original
	case ForceSSH
	case ForceHttps
}

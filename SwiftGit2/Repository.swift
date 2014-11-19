//
//  Repository.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import LlamaKit

/// A git repository.
final public class Repository {
	
	// MARK: - Creating Repositories
	
	/// Load the repository at the given URL.
	///
	/// URL - The URL of the repository.
	///
	/// Returns a `Result` with a `Repository` or an error.
	class public func atURL(URL: NSURL) -> Result<Repository> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let result = git_repository_open(pointer, URL.fileSystemRepresentation)
		
		if result < GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let repository = Repository(pointer: pointer.memory)
		pointer.dealloc(1)
		return success(repository)
	}
	
	// MARK: - Initializers
	
	/// Create an instance with a libgit2 `git_repository` object.
	public init(pointer: COpaquePointer) {
		self.pointer = pointer
		
		let path = git_repository_workdir(pointer)
		self.directoryURL = (path == nil ? nil : NSURL.fileURLWithPath(NSString(CString: path, encoding: NSUTF8StringEncoding)!, isDirectory: true))
	}
	
	deinit {
		git_repository_free(pointer)
	}
	
	// MARK: - Properties
	
	/// The underlying libgit2 `git_repository` object.
	public let pointer: COpaquePointer
	
	/// The URL of the repository's working directory, or `nil` if the
	/// repository is bare.
	public let directoryURL: NSURL?
}

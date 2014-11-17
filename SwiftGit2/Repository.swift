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
public class Repository {
	let git_repository: COpaquePointer
	
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
		
		let repository = Repository(git_repository: pointer.memory)
		pointer.dealloc(1)
		return success(repository)
	}
	
	init(git_repository: COpaquePointer) {
		self.git_repository = git_repository
		
		let path = git_repository_workdir(git_repository)
		self.directoryURL = (path == nil ? nil : NSURL.fileURLWithPath(NSString(CString: path, encoding: NSUTF8StringEncoding)!, isDirectory: true))
	}
	
	deinit {
		git_repository_free(git_repository)
	}
	
	/// The URL of the repository's working directory, or `nil` if the
	/// repository is bare.
	public let directoryURL: NSURL?
}

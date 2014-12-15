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
	
	// MARK: - Object Lookups
	
	/// Loads the blob with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns the blob if it exists, or an error.
	public func blobWithOID(oid: OID) -> Result<Blob> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let repository = self.pointer
		var oid = oid.oid
		let result = git_object_lookup(pointer, repository, &oid, GIT_OBJ_BLOB)
		
		if result < GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let blob = Blob(pointer.memory)
		git_object_free(pointer.memory)
		pointer.dealloc(1)
		return success(blob)
	}

	/// Loads the commit with the given OID.
	///
	/// oid - The OID of the commit to look up.
	///
	/// Returns the commit if it exists, or an error.
	public func commitWithOID(oid: OID) -> Result<Commit> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let repository = self.pointer
		var oid = oid.oid
		let result = git_object_lookup(pointer, repository, &oid, GIT_OBJ_COMMIT)
		
		if result < GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let commit = Commit(pointer.memory)
		git_object_free(pointer.memory)
		pointer.dealloc(1)
		return success(commit)
	}
	
	/// Loads the tag with the given OID.
	///
	/// oid - The OID of the tag to look up.
	///
	/// Returns the tag if it exists, or an error.
	public func tagWithOID(oid: OID) -> Result<Tag> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let repository = self.pointer
		var oid = oid.oid
		let result = git_object_lookup(pointer, repository, &oid, GIT_OBJ_TAG)
		
		if result < GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let tag = Tag(pointer.memory)
		git_object_free(pointer.memory)
		pointer.dealloc(1)
		return success(tag)
	}
	
	/// Loads the tree with the given OID.
	///
	/// oid - The OID of the tree to look up.
	///
	/// Returns the tree if it exists, or an error.
	public func treeWithOID(oid: OID) -> Result<Tree> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let repository = self.pointer
		var oid = oid.oid
		let result = git_object_lookup(pointer, repository, &oid, GIT_OBJ_TREE)
		
		if result < GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let tree = Tree(pointer.memory)
		git_object_free(pointer.memory)
		pointer.dealloc(1)
		return success(tree)
	}
}

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
	
	/// Load a libgit2 object and transform it to something else.
	///
	/// oid       - The OID of the object to look up.
	/// type      - The type of the object to look up.
	/// transform - A function that takes the libgit2 object and transforms it
	///             into something else.
	///
	/// Returns the result of calling `transform` or an error if the object
	/// cannot be loaded.
	func withLibgit2Object<T>(oid: OID, type: git_otype, transform: COpaquePointer -> Result<T>) -> Result<T> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let repository = self.pointer
		var oid = oid.oid
		let result = git_object_lookup(pointer, repository, &oid, type)
		
		if result != GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let value = transform(pointer.memory)
		git_object_free(pointer.memory)
		pointer.dealloc(1)
		return value
	}
	
	func withLibgit2Object<T>(oid: OID, type: git_otype, transform: COpaquePointer -> T) -> Result<T> {
		return withLibgit2Object(oid, type: type) { success(transform($0)) }
	}
	
	/// Loads the object with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns a `Blob`, `Commit`, `Tag`, or `Tree` if one exists, or an error.
	public func objectWithOID(oid: OID) -> Result<ObjectType> {
		return withLibgit2Object(oid, type: GIT_OBJ_ANY) { object in
			let type = git_object_type(object)
			if type == Blob.type {
				return success(Blob(object))
			} else if type == Commit.type {
				return success(Commit(object))
			} else if type == Tag.type {
				return success(Tag(object))
			} else if type == Tree.type {
				return success(Tree(object))
			}
			return failure()
		}
	}
	
	/// Loads the blob with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns the blob if it exists, or an error.
	public func blobWithOID(oid: OID) -> Result<Blob> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_BLOB) { Blob($0) }
	}

	/// Loads the commit with the given OID.
	///
	/// oid - The OID of the commit to look up.
	///
	/// Returns the commit if it exists, or an error.
	public func commitWithOID(oid: OID) -> Result<Commit> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_COMMIT) { Commit($0) }
	}
	
	/// Loads the tag with the given OID.
	///
	/// oid - The OID of the tag to look up.
	///
	/// Returns the tag if it exists, or an error.
	public func tagWithOID(oid: OID) -> Result<Tag> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_TAG) { Tag($0) }
	}
	
	/// Loads the tree with the given OID.
	///
	/// oid - The OID of the tree to look up.
	///
	/// Returns the tree if it exists, or an error.
	public func treeWithOID(oid: OID) -> Result<Tree> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_TREE) { Tree($0) }
	}
	
	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func objectFromPointer<T>(pointer: PointerTo<T>) -> Result<T> {
		return self.withLibgit2Object(pointer.oid, type: pointer.type) { T($0) }
	}
	
	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func objectFromPointer(pointer: Pointer) -> Result<ObjectType> {
		switch pointer {
		case let .Blob(oid):
			return blobWithOID(oid).map { $0 as ObjectType }
		case let .Commit(oid):
			return commitWithOID(oid).map { $0 as ObjectType }
		case let .Tag(oid):
			return tagWithOID(oid).map { $0 as ObjectType }
		case let .Tree(oid):
			return treeWithOID(oid).map { $0 as ObjectType }
		}
	}
	
	// MARK: - Remote Lookups
	
	/// Loads all the remotes in the repository.
	///
	/// Returns an array of remotes, or an error.
	public func allRemotes() -> Result<[Remote]> {
		let pointer = UnsafeMutablePointer<git_strarray>.alloc(1)
		let repository = self.pointer
		let result = git_remote_list(pointer, repository)
		
		if result != GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let strarray = pointer.memory
		let remotes: [Result<Remote>] = map(0..<strarray.count) {
			let name = String.fromCString(strarray.strings[Int($0)])!
			return self.remoteWithName(name)
		}
		pointer.dealloc(1)
		
		let error = remotes.reduce(nil) { $0 == nil ? $0 : $1.error() }
		if let error = error {
			return failure(error)
		}
		return success(remotes.map { $0.value()! })
	}
	
	/// Load a remote from the repository.
	///
	/// name - The name of the remote.
	///
	/// Returns the remote if it exists, or an error.
	public func remoteWithName(name: String) -> Result<Remote> {
		let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
		let repository = self.pointer
		let result = git_remote_lookup(pointer, repository, name.cStringUsingEncoding(NSUTF8StringEncoding)!)
		
		if result != GIT_OK.value {
			pointer.dealloc(1)
			return failure()
		}
		
		let value = Remote(pointer.memory)
		git_remote_free(pointer.memory)
		pointer.dealloc(1)
		return success(value)
	}
	
	// MARK: - Reference Lookups
	
	public func referenceWithName(name: String) -> Result<Reference> {
		return failure()
	}
	
	public func allBranches() -> Result<[Branch]> {
		return failure()
	}
	
	public func localBranches() -> Result<[Branch]> {
		return failure()
	}
	
	public func remoteBranches() -> Result<[Branch]> {
		return failure()
	}
	
	public func branchWithName(name: String) -> Result<Branch> {
		return failure()
	}
	
	public func allTags() -> Result<[TagReference]> {
		return failure()
	}
	
	public func tagWithName(name: String) -> Result<TagReference> {
		return failure()
	}
}

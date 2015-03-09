//
//  Repository.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import LlamaKit

extension git_strarray {
	func filter(f: (String) -> Bool) -> [String] {
		return map { $0 }.filter(f)
	}
	
	func map<T>(f: (String) -> T) -> [T] {
		return Swift.map(0..<self.count) {
			let string = String.fromCString(self.strings[Int($0)])!
			return f(string)
		}
	}
}

/// A git repository.
final public class Repository {
	
	// MARK: - Creating Repositories
	
	/// Load the repository at the given URL.
	///
	/// URL - The URL of the repository.
	///
	/// Returns a `Result` with a `Repository` or an error.
	class public func atURL(URL: NSURL) -> Result<Repository, NSError> {
		var pointer: COpaquePointer = nil
		let result = git_repository_open(&pointer, URL.fileSystemRepresentation)
		
		if result != GIT_OK.value {
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_repository_open"))
		}
		
		let repository = Repository(pointer)
		return success(repository)
	}
	
	// MARK: - Initializers
	
	/// Create an instance with a libgit2 `git_repository` object.
	///
	/// The Repository assumes ownership of the `git_repository` object.
	public init(_ pointer: COpaquePointer) {
		self.pointer = pointer
		
		let path = git_repository_workdir(pointer)
		self.directoryURL = (path == nil ? nil : NSURL.fileURLWithPath(String.fromCString(path)!, isDirectory: true))
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
	func withLibgit2Object<T>(oid: OID, type: git_otype, transform: COpaquePointer -> Result<T, NSError>) -> Result<T, NSError> {
		var pointer: COpaquePointer = nil
		var oid = oid.oid
		let result = git_object_lookup(&pointer, self.pointer, &oid, type)
		
		if result != GIT_OK.value {
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_object_lookup"))
		}
		
		let value = transform(pointer)
		git_object_free(pointer)
		return value
	}
	
	func withLibgit2Object<T>(oid: OID, type: git_otype, transform: COpaquePointer -> T) -> Result<T, NSError> {
		return withLibgit2Object(oid, type: type) { success(transform($0)) }
	}
	
	/// Loads the object with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns a `Blob`, `Commit`, `Tag`, or `Tree` if one exists, or an error.
	public func objectWithOID(oid: OID) -> Result<ObjectType, NSError> {
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

			let error = NSError(
				domain: "org.libgit2.SwiftGit2",
				code: 1,
				userInfo: [
					NSLocalizedDescriptionKey: "Unrecognized git_otype '\(type)' for oid '\(oid)'."
				]
			)
			return failure(error)
		}
	}
	
	/// Loads the blob with the given OID.
	///
	/// oid - The OID of the blob to look up.
	///
	/// Returns the blob if it exists, or an error.
	public func blobWithOID(oid: OID) -> Result<Blob, NSError> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_BLOB) { Blob($0) }
	}

	/// Loads the commit with the given OID.
	///
	/// oid - The OID of the commit to look up.
	///
	/// Returns the commit if it exists, or an error.
	public func commitWithOID(oid: OID) -> Result<Commit, NSError> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_COMMIT) { Commit($0) }
	}
	
	/// Loads the tag with the given OID.
	///
	/// oid - The OID of the tag to look up.
	///
	/// Returns the tag if it exists, or an error.
	public func tagWithOID(oid: OID) -> Result<Tag, NSError> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_TAG) { Tag($0) }
	}
	
	/// Loads the tree with the given OID.
	///
	/// oid - The OID of the tree to look up.
	///
	/// Returns the tree if it exists, or an error.
	public func treeWithOID(oid: OID) -> Result<Tree, NSError> {
		return self.withLibgit2Object(oid, type: GIT_OBJ_TREE) { Tree($0) }
	}
	
	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func objectFromPointer<T>(pointer: PointerTo<T>) -> Result<T, NSError> {
		return self.withLibgit2Object(pointer.oid, type: pointer.type) { T($0) }
	}
	
	/// Loads the referenced object from the pointer.
	///
	/// pointer - A pointer to an object.
	///
	/// Returns the object if it exists, or an error.
	public func objectFromPointer(pointer: Pointer) -> Result<ObjectType, NSError> {
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
	public func allRemotes() -> Result<[Remote], NSError> {
		let pointer = UnsafeMutablePointer<git_strarray>.alloc(1)
		let result = git_remote_list(pointer, self.pointer)
		
		if result != GIT_OK.value {
			pointer.dealloc(1)
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_remote_list"))
		}
		
		let strarray = pointer.memory
		let remotes: [Result<Remote, NSError>] = strarray.map {
			return self.remoteWithName($0)
		}
		git_strarray_free(pointer)
		pointer.dealloc(1)
		
		let error = remotes.reduce(nil) { $0 == nil ? $0 : $1.error }
		if let error = error {
			return failure(error)
		}
		return success(remotes.map { $0.value! })
	}
	
	/// Load a remote from the repository.
	///
	/// name - The name of the remote.
	///
	/// Returns the remote if it exists, or an error.
	public func remoteWithName(name: String) -> Result<Remote, NSError> {
		var pointer: COpaquePointer = nil
		let result = git_remote_lookup(&pointer, self.pointer, name)
		
		if result != GIT_OK.value {
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_remote_lookup"))
		}
		
		let value = Remote(pointer)
		git_remote_free(pointer)
		return success(value)
	}
	
	// MARK: - Reference Lookups
	
	/// Load all the references with the given prefix (e.g. "refs/heads/")
	public func referencesWithPrefix(prefix: String) -> Result<[ReferenceType], NSError> {
		let pointer = UnsafeMutablePointer<git_strarray>.alloc(1)
		let result = git_reference_list(pointer, self.pointer)
		
		if result != GIT_OK.value {
			pointer.dealloc(1)
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_reference_list"))
		}
		
		let strarray = pointer.memory
		let references = strarray
			.filter {
				$0.hasPrefix(prefix)
			}
			.map {
				self.referenceWithName($0)
			}
		git_strarray_free(pointer)
		pointer.dealloc(1)
		
		let error = references.reduce(nil) { $0 == nil ? $0 : $1.error }
		if let error = error {
			return failure(error)
		}
		return success(references.map { $0.value! })
	}
	
	/// Load the reference with the given long name (e.g. "refs/heads/master")
	///
	/// If the reference is a branch, a `Branch` will be returned. If the
	/// reference is a tag, a `TagReference` will be returned. Otherwise, a
	/// `Reference` will be returned.
	public func referenceWithName(name: String) -> Result<ReferenceType, NSError> {
		var pointer: COpaquePointer = nil
		let result = git_reference_lookup(&pointer, self.pointer, name)
		
		if result != GIT_OK.value {
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_reference_lookup"))
		}
		
		let value = referenceWithLibGit2Reference(pointer)
		git_reference_free(pointer)
		return success(value)
	}
	
	/// Load and return a list of all local branches.
	public func localBranches() -> Result<[Branch], NSError> {
		return referencesWithPrefix("refs/heads/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! Branch }
			}
	}
	
	/// Load and return a list of all remote branches.
	public func remoteBranches() -> Result<[Branch], NSError> {
		return referencesWithPrefix("refs/remotes/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! Branch }
			}
	}
	
	/// Load the local branch with the given name (e.g., "master").
	public func localBranchWithName(name: String) -> Result<Branch, NSError> {
		return referenceWithName("refs/heads/" + name).map { $0 as! Branch }
	}
	
	/// Load the remote branch with the given name (e.g., "origin/master").
	public func remoteBranchWithName(name: String) -> Result<Branch, NSError> {
		return referenceWithName("refs/remotes/" + name).map { $0 as! Branch }
	}
	
	/// Load and return a list of all the `TagReference`s.
	public func allTags() -> Result<[TagReference], NSError> {
		return referencesWithPrefix("refs/tags/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! TagReference }
			}
	}
	
	/// Load the tag with the given name (e.g., "tag-2").
	public func tagWithName(name: String) -> Result<TagReference, NSError> {
		return referenceWithName("refs/tags/" + name).map { $0 as! TagReference }
	}
	
	// MARK: - Working Directory
	
	/// Load the reference pointed at by HEAD.
	///
	/// When on a branch, this will return the current `Branch`.
	public func HEAD() -> Result<ReferenceType, NSError> {
		var pointer: COpaquePointer = nil
		let result = git_repository_head(&pointer, self.pointer)
		if result != GIT_OK.value {
			return failure(libGit2Error(result, libGit2PointOfFailure: "git_repository_head"))
		}
		let value = referenceWithLibGit2Reference(pointer)
		git_reference_free(pointer)
		return success(value)
	}
}

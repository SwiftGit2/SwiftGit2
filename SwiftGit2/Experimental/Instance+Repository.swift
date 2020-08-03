//
//  Instance+Repository.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

extension Repository : InstanceType {
	public func free(pointer: OpaquePointer) {
		git_repository_free(pointer)
	}
}

public extension Repository {
	class func instance(at url: URL) -> Result<Instance<Repository>, NSError> {
		var pointer: OpaquePointer? = nil
		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_open(&pointer, $0)
		}

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
		}
		
		return Result.success(Instance<Repository>(pointer!))
	}
}

public extension Instance where Type == Repository {
	
	
	/// Load and return a list of all local branches.
	func localBranches() -> Result<[Branch], NSError> {
		return references(withPrefix: "refs/heads/")
			.map { (refs: [ReferenceType]) in
				return refs.map { $0 as! Branch }
			}
	}
}
	

public extension Instance where Type == Repository {
	/// Load all the references with the given prefix (e.g. "refs/heads/")
	func references(withPrefix prefix: String) -> Result<[ReferenceType], NSError> {
		let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
		defer {
			git_strarray_free(pointer)
			pointer.deallocate()
		}
		
		let result = git_reference_list(pointer, self.pointer)

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_list"))
		}

		let strarray = pointer.pointee
		let references = strarray
			.filter { $0.hasPrefix(prefix) }
			.map {
				self.__reference(named: $0)
			}
		

		return references.aggregateResult()
	}
	
	///
	/// If the reference is a branch, a `Branch` will be returned. If the
	/// reference is a tag, a `TagReference` will be returned. Otherwise, a
	/// `Reference` will be returned.
	func __reference(named name: String) -> Result<ReferenceType, NSError> {
		var pointer: OpaquePointer? = nil
		let result = git_reference_lookup(&pointer, self.pointer, name)

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_reference_lookup"))
		}

		let value = referenceWithLibGit2Reference(pointer!)
		git_reference_free(pointer)
		return Result.success(value)
	}
	
	func reference(name: String) -> Result<Instance<Reference>, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result({ Instance<Reference>(pointer!) }, pointOfFailure: "git_object_lookup") {
			git_reference_lookup(&pointer, self.pointer, name)
		}
	}
}

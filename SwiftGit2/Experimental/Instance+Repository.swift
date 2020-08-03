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
	class func at(url: URL) -> Result<Instance<Repository>, NSError> {
		var pointer: OpaquePointer? = nil
		let result = url.withUnsafeFileSystemRepresentation {
			git_repository_open(&pointer, $0)
		}

		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
		}
		
		return Result.success(Instance<Repository>(pointer!))
	}
	
	class func create(url: URL) -> Result<Instance<Repository>, NSError> {
		var pointer: OpaquePointer? = nil
		
		
		return _result( { Instance<Repository>(pointer!) }, pointOfFailure: "git_object_lookup") {
			url.withUnsafeFileSystemRepresentation {
				git_repository_init(&pointer, $0, 0)
			}
		}
	}
}

public extension Instance where Type == Repository {
	/// Load and return a list of all local branches.
	func branches( _ location: BranchLocation) -> Result<[InstanceBranch], NSError> {
		switch location {
		case .local:		return references(withPrefix: "refs/heads/")
		case .remote: 		return references(withPrefix: "refs/remotes/")
		}
	}
	
	func index() -> Result<Instance<Index>, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Instance<Index>(pointer!) }, pointOfFailure: "git_repository_index") {
			git_repository_index(&pointer, pointer)
		}
	}
	
	func reset(path: String) -> Result<(), NSError> {
		let dir = path
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (dir as NSString).utf8String)
		var paths = git_strarray(strings: &dirPointer, count: 1)
		
		return HEAD().flatMap { self.commit($0.oid) }.flatMap { comit in
				
			let result = git_reset_default(self.pointer, comit.pointer, &paths)
			guard result == GIT_OK.rawValue else {
				return .failure(NSError(gitError: result, pointOfFailure: "git_reset_default"))
			}
				
			return .success(())
		}
	}

}
	

public extension Instance where Type == Repository {
	/// Load all the references with the given prefix (e.g. "refs/heads/")
	func references(withPrefix prefix: String) -> Result<[InstanceBranch], NSError> {
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
			.map { self.reference(name: $0) }
		

		return references.aggregateResult()
			.map { $0.compactMap { InstanceBranch(instance: $0) } }
	}
	
	func reference(name: String) -> Result<Instance<Reference>, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result({ Instance<Reference>(pointer!) }, pointOfFailure: "git_object_lookup") {
			git_reference_lookup(&pointer, self.pointer, name)
		}
	}
	
	func HEAD() -> Result<ReferenceType, NSError> {
		var pointer: OpaquePointer? = nil
		let result = git_repository_head(&pointer, self.pointer)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_head"))
		}
		let value = referenceWithLibGit2Reference(pointer!)
		git_reference_free(pointer)
		return Result.success(value)
	}
	
	func commit(_ oid: OID) -> Result<Commit, NSError> {
		return withGitObject(oid, type: GIT_OBJECT_COMMIT) { Commit($0) }
	}
	
	private func withGitObject<T>(_ oid: OID, type: git_object_t,
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
	
	private func withGitObject<T>(_ oid: OID, type: git_object_t, transform: (OpaquePointer) -> T) -> Result<T, NSError> {
		return withGitObject(oid, type: type) { Result.success(transform($0)) }
	}

}

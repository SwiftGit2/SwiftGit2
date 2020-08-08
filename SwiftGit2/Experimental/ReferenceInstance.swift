//
//  ReferenceInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class ReferenceInstance : InstanceProtocol {
	public var pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_reference_free(pointer)
	}
	
	var oid 	 		: OID  { OID(git_reference_target(pointer).pointee) }
	var isLocalBranch 	: Bool { git_reference_is_branch(pointer) 	!= 0 }
	var isRemoteBranch	: Bool { git_reference_is_remote(pointer) 	!= 0 }
	var isTag    		: Bool { git_reference_is_tag(pointer) 	!= 0 }
	
	var asBranch		: BranchProtocol? {
		if isLocalBranch || isRemoteBranch {
			return self as BranchProtocol
		}
		return nil
	}
}

public extension RepositoryInstance {
	func HEAD() -> Result<ReferenceInstance, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result({ ReferenceInstance(pointer!) }, pointOfFailure: "git_repository_head") {
			git_repository_head(&pointer, self.pointer)
		}
	}
	
	func references(withPrefix prefix: String) -> Result<[ReferenceInstance], NSError> {
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
		//.map { $0.compactMap { InstanceBranch(instance: $0) } }
	}
	
	func reference(name: String) -> Result<ReferenceInstance, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result({ ReferenceInstance(pointer!) }, pointOfFailure: "git_reference_lookup") {
			git_reference_lookup(&pointer, self.pointer, name)
		}
	}
}

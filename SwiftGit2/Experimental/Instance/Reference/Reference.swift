//
//  ReferenceInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Reference : InstanceProtocol {
	public var pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_reference_free(pointer)
	}
	
	var oid		: OID  { OID(git_reference_target(pointer).pointee) }
	var isTag	: Bool { git_reference_is_tag(pointer) != 0 }
	
	public func asBranch() -> Result<Branch, Error> {
		if isBranch || isRemote {
			return .success(self as Branch)
		}
		
		
		return Result.failure(NSError(gitError: 0, pointOfFailure: "asBranch"))
	}
	
	public var asBranch_ : Branch? {
		if isBranch || isRemote {
			return self as Branch
		}
		return nil
	}
}

public extension Repository {
	func HEAD() -> Result<Reference, Error> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Reference(pointer!) }, pointOfFailure: "git_repository_head") {
			git_repository_head(&pointer, self.pointer)
		}
	}
	
	var headIsUnborn: Bool {
		git_repository_head_unborn(self.pointer) == 1 ? true : false
	}
	
	var headIsDetached: Bool {
		let result: Int32 = git_repository_head_detached(self.pointer)
		return (result as NSNumber).boolValue
	}
	
	func references(withPrefix prefix: String) -> Result<[Reference], Error> {
		var strarray = git_strarray()
		defer {
			// free results of the git_reference_list call
			git_strarray_free(&strarray)
		}
		
		return _result({ strarray }, pointOfFailure: "git_reference_list") {
			git_reference_list(&strarray, self.pointer)
		}.flatMap {
			$0.filter { $0.hasPrefix(prefix) }
			.flatMap { self.reference(name: $0) }
		}
	}
	
	func reference(name: String) -> Result<Reference, Error> {
		var pointer: OpaquePointer? = nil
		
		return _result({ Reference(pointer!) }, pointOfFailure: "git_reference_lookup") {
			git_reference_lookup(&pointer, self.pointer, name)
		}
	}
}

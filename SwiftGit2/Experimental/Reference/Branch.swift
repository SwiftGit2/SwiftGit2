//
//  BranchInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Branch
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public enum BranchLocation {
	case local
	case remote
}

public protocol Branch: InstanceProtocol {
	var shortName	: String	{ get }
	var name		: String	{ get }
	var commitOID_	: OID?		{ get }
}

public extension Branch {
	var isBranch : Bool { git_reference_is_branch(pointer) != 0 }
	var isRemote : Bool { git_reference_is_remote(pointer) != 0 }

	var isLocalBranch	: Bool { self.name.starts(with: "refs/heads/") }
	var isRemoteBranch	: Bool { self.name.starts(with: "refs/remotes/") }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Reference
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extension Reference : Branch {}
	
extension Branch {
	public var shortName 	: String 	{ getName() }
	public var name 		: String 	{ getLongName() }
	public var commitOID_	: OID? 		{ getCommitOID_() }
	public var commitOID	: Result<OID, NSError> { getCommitOid() }
}

extension Branch{
	
	/// can be called only for local branch;
	///
	/// newName looks like "BrowserGridItemView" BUT NOT LIKE "refs/heads/BrowserGridItemView"
	public func setUpstreamName(newName: String) -> Result<(), NSError> {
		let cleanedName = newName
							.replace(of: "refs/heads/", to: "")
							.replace(of: "refs/remotes/", to: "")
		
		return _result({}, pointOfFailure: "git_branch_set_upstream" ) {
			cleanedName.withCString { newBrName in
				git_branch_set_upstream(self.pointer, newBrName);
			}
		}
	}
}

struct Tuple<T1,T2> {
	var value: (T1, T2)
	init(value: (T1, T2)) {
		self.value = value
	}
}

extension Tuple where T1 == Branch, T2 == Repository {
	func commit() -> Result<Commit, NSError> {
		let (branch, repo) = self.value
		return branch.commitOID.flatMap { repo.instanciate($0) }
	}
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Repository
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension Repository {
	func branches( _ location: BranchLocation) -> Result<[Branch], NSError> {		
		switch location {
		case .local:		return references(withPrefix: "refs/heads/")
										.flatMap { $0.map { $0.asBranch() }.aggregateResult() }
		case .remote: 		return references(withPrefix: "refs/remotes/")
										.flatMap { $0.map { $0.asBranch() }.aggregateResult() }
		}
	}
	
	/// Get upstream name by branchName
	func upstreamName(branchName: String) -> Result<String, NSError> {
		let buf_ptr = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
		buf_ptr.pointee = git_buf(ptr: nil, asize: 0, size: 0)
		
		return _result({Buffer(pointer: buf_ptr)}, pointOfFailure: "" ) {
			branchName.withCString { refname in
				git_branch_upstream_name(buf_ptr, self.pointer, refname)
			}
		}.map { $0.asString() ?? "" }
	}
}

private extension Branch {
	func getName() -> String {
		var namePointer: UnsafePointer<Int8>? = nil
		let success = git_branch_name(&namePointer, pointer)
		guard success == GIT_OK.rawValue else {
			return ""
		}
		return String(validatingUTF8: namePointer!) ?? ""
	}
	
	func getLongName() -> String {
		return String(validatingUTF8: git_reference_name(pointer)) ?? ""
	}
	
	func getCommitOid() -> Result<OID, NSError> {
		if git_reference_type(pointer).rawValue == GIT_REFERENCE_SYMBOLIC.rawValue {
			var resolved: OpaquePointer? = nil
			defer {
				git_reference_free(resolved)
			}
			
			return _result( { resolved }, pointOfFailure: "git_reference_resolve") {
				git_reference_resolve(&resolved, self.pointer)
			}.map { OID(git_reference_target($0).pointee) }
			
		} else {
			return .success( OID(git_reference_target(pointer).pointee) )
		}
	}
	
	func getCommitOID_() -> OID? {
		if git_reference_type(pointer).rawValue == GIT_REFERENCE_SYMBOLIC.rawValue {
			var resolved: OpaquePointer? = nil
			defer {
				git_reference_free(resolved)
			}
			
			let success = git_reference_resolve(&resolved, pointer)
			guard success == GIT_OK.rawValue else {
				return nil
			}
			return OID(git_reference_target(resolved).pointee)
			
		} else {
			return OID(git_reference_target(pointer).pointee)
		}
	}
}


fileprivate extension String {
	func replace(of: String, to: String) -> String {
		return self.replacingOccurrences(of: of, with: to, options: .regularExpression, range: nil)
	}
}

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
	var commitOID	: Result<OID, NSError> { get }
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
	public var shortName 	: String 	{ ( try? getNameInternal().get() ) ?? "" }
	public var name 		: String 	{ getLongName() }
	public var commitOID	: Result<OID, NSError> { getCommitOid() }
}

public extension Result where Failure == NSError {
	func withSwiftError() -> Result<Success, Error> {
		switch self {
		case .success(let success):
			return .success(success)
		case .failure(let error):
			return .failure(error)
		}
	}
}

extension Branch {
	
	/// can be called only for local branch;
	///
	/// newName looks like "BrowserGridItemView" BUT NOT LIKE "refs/heads/BrowserGridItemView"
	public func setUpstreamName(newName: String) -> Result<Branch, NSError> {
		let cleanedName = newName.replace(of: "refs/heads/", to: "")
		
		return _result({ self }, pointOfFailure: "git_branch_set_upstream" ) {
			cleanedName.withCString { newBrName in
				git_branch_set_upstream(self.pointer, newBrName);
			}
		}
	}
	
	/// can be called only for local branch;
	///
	/// newNameWithPath MUST BE WITH "refs/heads/"
	/// Will reset assigned upstream Name
	public func setLocalName(newNameWithPath: String) -> Result<Branch, NSError> {
		guard   newNameWithPath.contains("refs/heads/")
		else { return .failure(BranchError.NameIsNotLocal as NSError) }
		
		return (self as! Reference).rename(newNameWithPath).flatMap { $0.asBranch() }
	}
}

public extension Duo where T1 == Branch, T2 == Repository {
	func commit() -> Result<Commit, NSError> {
		let (branch, repo) = self.value
		return branch.commitOID.flatMap { repo.instanciate($0) }
	}
	
	func newBranch(withName name: String) -> Result<Reference, NSError> {
		let (branch, repo) = self.value
		
		return branch.commitOID
			.flatMap { Duo<OID,Repository>(($0, repo)).commit() }
			.flatMap { commit in repo.createBranch(from: commit, withName: name)  }
	}
}

public extension Duo where T1 == Branch, T2 == Remote {
	/// Push local branch changes to remote branch
	func push(credentials: Credentials_OLD) -> Result<(), NSError> {
		let (branch, remoteRepo) = self.value
		
		var opts = pushOptions(credentials: credentials)
		
		return remoteRepo.push(branchName: branch.name, options: &opts )
	}
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Repository
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// High Level code
public extension Repository {
	func push(remoteRepoName: String, localBranchName: String, credentials: Credentials_OLD) -> Result<(), NSError> {
		let set = XR.Set()
		
		//Huck, but works
		//let remoteType  = credentials.isSsh() ? RemoteType.ForceSSH  : .ForceHttps
		let remote = self.remoteRepo(named: remoteRepoName, remoteType: .ForceHttps )
		
		return set.with( remote )
			.flatMap{ $0.with( self.reference(name: localBranchName).flatMap{ $0.asBranch() } ) } // branch
			.flatMap{ set in Duo((set[Branch.self], set[Remote.self] )).push(credentials: credentials) }
	}
}

// Low Level code
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
		
		return  _result({Buffer(pointer: buf_ptr)}, pointOfFailure: "" ) {
			branchName.withCString { refname in
				git_branch_upstream_name(buf_ptr, self.pointer, refname)
			}
		}
		.flatMap { $0.asStringRez() }
	}
}

private extension Branch {
	private func getNameInternal() -> Result<String, NSError> {
		var namePointer: UnsafePointer<Int8>? = nil
		
		return _result( { String(validatingUTF8: namePointer!) ?? "" }, pointOfFailure: "git_branch_name") {
			git_branch_name(&namePointer, pointer)
		}
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
}

fileprivate extension Remote {
	func push(branchName: String, options: UnsafePointer<git_push_options> ) -> Result<(), NSError> {
		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (branchName as NSString).utf8String)
		var refs = git_strarray(strings: &dirPointer, count: 1)

		print("Trying to push ''\(self.name)'' remote with URL:''\(self.URL)''")
		
		return _result( (), pointOfFailure: "git_remote_push") {
			git_remote_push(self.pointer, &refs, options)
		}
	}
}

fileprivate extension String {
	func replace(of: String, to: String) -> String {
		return self.replacingOccurrences(of: of, with: to, options: .regularExpression, range: nil)
	}
}

fileprivate func pushOptions(credentials: Credentials_OLD) -> git_push_options {
	let pointer = UnsafeMutablePointer<git_push_options>.allocate(capacity: 1)
	git_push_init_options(pointer, UInt32(GIT_PUSH_OPTIONS_VERSION))
	
	var options = pointer.move()
	
	pointer.deallocate()
	
	options.callbacks.payload = credentials.toPointer()
	options.callbacks.credentials = credentialsCallback
	
	return options
}

////////////////////////////////////////////////////////////////////
///ERRORS
////////////////////////////////////////////////////////////////////

enum BranchError: Error {
	//case BranchNameIncorrectFormat
	case NameIsNotLocal
	//case NameMustNotContainsRefsRemotes
}

extension BranchError: LocalizedError {
  public var errorDescription: String? {
	switch self {
//	case .BranchNameIncorrectFormat:
//	  return "Name must include 'refs' or 'home' block"
	case .NameIsNotLocal:
	  return "Name must be Local. It must have include 'refs/heads/'"
//	case .NameMustNotContainsRefsRemotes:
//	  return "Name must be Remote. But it must not contain 'refs/remotes/'"
	}
  }
}

extension Credentials_OLD {
	func isSsh() -> Bool {
		switch self {
		case .ssh(_,_,_):
			return true
			default:
			return false
		}
	}
}

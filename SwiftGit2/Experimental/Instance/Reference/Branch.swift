//
//  BranchInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

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
	var commitOID	: Result<OID, Error> { get }
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
	public var shortName 	: String 	{ ( try? nameInternal().get() ) ?? "" }
	public var name 		: String 	{ longName() }
	public var commitOID	: Result<OID, Error> { commitOid() }
}

public extension Branch {
	/// can be called only for local branch;
	///
	/// newName looks like "BrowserGridItemView" BUT NOT LIKE "refs/heads/BrowserGridItemView"
	func setUpstreamName(newName: String) -> Result<Branch, Error> {
		let cleanedName = newName.replace(of: "refs/heads/", to: "")
		
		return _result({ self }, pointOfFailure: "git_branch_set_upstream" ) {
			cleanedName.withCString { newBrName in
				git_branch_set_upstream(self.pointer, newBrName);
			}
		}
	}
	
	/// can be called only for local branch;
	func upstreamName(clean: Bool = false) -> Result<String, Error> {
		if clean {
			return upstream().map{ $0.name.replace(of: "refs/remotes/", to: "") }
		}
		
		return upstream().map{ $0.name }
	}
	
	/// Can be used only on local branch
	func upstream() -> Result<Branch, Error> {
		var resolved: OpaquePointer? = nil
		
		return git_try("git_branch_upstream") { git_branch_upstream(&resolved, self.pointer) }
			.flatMap { Reference(resolved!).asBranch() }
	}
	
	/// can be called only for local branch;
	///
	/// newNameWithPath MUST BE WITH "refs/heads/"
	/// Will reset assigned upstream Name
	func setLocalName(newNameWithPath: String) -> Result<Branch, Error> {
		guard   newNameWithPath.contains("refs/heads/")
		else { return .failure(BranchError.NameIsNotLocal as Error) }
		
		return (self as! Reference).rename(newNameWithPath).flatMap { $0.asBranch() }
	}
}

public extension Duo where T1 == Branch, T2 == Repository {
	func commit() -> Result<Commit, Error> {
		let (branch, repo) = self.value
		return branch.commitOID.flatMap { repo.instanciate($0) }
	}
	
	func newBranch(withName name: String) -> Result<Reference, Error> {
		let (branch, repo) = self.value
		
		return branch.commitOID
			.flatMap { Duo<OID,Repository>($0, repo).commit() }
			.flatMap { commit in repo.createBranch(from: commit, withName: name)  }
	}
	
	fileprivate func remoteName() -> Result<String, Error> {
		let (branch, repo) = self.value
		var buf = git_buf(ptr: nil, asize: 0, size: 0)
		
		return git_try("git_branch_upstream_remote") {
			return branch.longName().withCString { branchName in
				git_branch_upstream_remote(&buf, repo.pointer, branchName);
			}
		}.flatMap { Buffer(buf: buf).asString() }
		
	}
	
	///Gets REMOTE item from local branch. Doesn't works with remote branch
	func remote() -> Result<Remote, Error> {
		let (_, repo) = self.value
		
		return remoteName()
			.flatMap { remoteName in
				repo.remoteRepo(named: remoteName, remoteType: .Original)
			}
		
	}
}

public extension Duo where T1 == Branch, T2 == Remote {
	/// Push local branch changes to remote branch
	func push(auth: Auth = .auto) -> Result<(), Error> {
		let (branch, remote) = self.value
		return remote.push(branchName: branch.name, options: PushOptions(auth: auth) )
	}
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Repository
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// High Level code
public extension Repository {
	func push(remoteRepoName: String, localBranchName: String, auth: Auth) -> Result<(), Error> {
		let set = XR.Set()
		
		//Huck, but works
		//let remoteType  = credentials.isSsh() ? RemoteType.ForceSSH  : .ForceHttps
		let remote = self.remoteRepo(named: remoteRepoName, remoteType: .ForceHttps )
		
		return set.with( remote )
			.flatMap{ $0.with( self.reference(name: localBranchName).flatMap{ $0.asBranch() } ) } // branch
			.flatMap{ set in Duo(set[Branch.self], set[Remote.self]).push(auth: auth) }
	}
}

// Low Level code
public extension Repository {
	func branches( _ location: BranchLocation) -> Result<[Branch], Error> {		
		switch location {
		case .local:
			return references(withPrefix: "refs/heads/")
				.flatMap { $0.flatMap { $0.asBranch() } }
			
		case .remote:
			return references(withPrefix: "refs/remotes/")
				.flatMap { $0.flatMap { $0.asBranch() } }
		}
	}
	
	/// Get upstream name by branchName
	func upstreamName(branchName: String) -> Result<String, Error> {
		var buf = git_buf(ptr: nil, asize: 0, size: 0)
		
		return  _result({Buffer(buf: buf)}, pointOfFailure: "" ) {
			branchName.withCString { refname in
				git_branch_upstream_name(&buf, self.pointer, refname)
			}
		}
		.flatMap { $0.asString() }
	}
}

private extension Branch {
	private func nameInternal() -> Result<String, Error> {
		var namePointer: UnsafePointer<Int8>? = nil
		
		return _result( { String(validatingUTF8: namePointer!) ?? "" }, pointOfFailure: "git_branch_name") {
			git_branch_name(&namePointer, pointer)
		}
	}
	
	func longName() -> String {
		return String(validatingUTF8: git_reference_name(pointer)) ?? ""
	}
	
	func commitOid() -> Result<OID, Error> {
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
	///Branch name must be full - with "refs/heads/"
	func push(branchName: String, options: PushOptions ) -> Result<(), Error> {
		print("Trying to push ''\(branchName)'' to remote ''\(self.name)'' with URL:''\(self.URL)''")
		
		return git_try("git_remote_push") {
			options.with_git_push_options { push_options in
				[branchName].with_git_strarray { strarray in
					git_remote_push(self.pointer, &strarray, &push_options)
				}
			}
		}
	}
}

fileprivate extension String {
	func replace(of: String, to: String) -> String {
		return self.replacingOccurrences(of: of, with: to, options: .regularExpression, range: nil)
	}
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

extension Credentials {
	func isSsh() -> Bool {
		switch self {
		case .ssh(_,_,_):
			return true
			default:
			return false
		}
	}
}

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



extension Branch{
	
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

let privateKey = """
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
"""

let publicKey = "AAAAB3NzaC1yc2EAAAADAQABAAACAQDOkKA9wnTakoQ2i9vJ3IpzCRySji6lBawRLUzch4jrFq54GZAt+8dDR/WTiGk6nlvAY0a5zN6Umqx+Ed1OCnrYg/IWZm5+gsdsURRaD3yRJdRluZHwYLgkbL2wAhl/kl13zFxwkcABJnKQnrAF1PiI28rmbBOLjoRngHLyB8Dy+zK0bgmgI7GqUnNo/F3MOarQ59DOtTcevGiTIJa+y2DDk2t7oGm6+/9k4oFZ0imQ9j0CH3jvfy9D540UKew6kVSAZiW6V/2mBPyCTzlVgeREmzXLW5HEkDfBbYWPS7LH7Hd1w8DvW7WAt6NDgug0L+7dgcWgVjsuFlkx5jgxKQKRHn2+dfESLpb+Kc9wMPydWYfQHKVUC+7Hoe7N4n8YvXievIuU+KZK7cavtvWhGtWSj8lUkZnhXnkiOai8yXTbIAD27LOVEAVi/7G5LZUeqTqTyF/dvCCljtGEY6p8N3iAgQA+zFD9Z12/QsKa/Fu/ZcGG6UkzaVK2PdHA/kkDEu0eYpoqw7rd8D+A+O1uVuAcYMBr2u7TOjixIrd8UdnfIsubNGP+A4MdvkcaCggEKfSN1V0rVSpyPhjtyC40q+WYPNYUzjqWeotj8nj7x+gHuod/uFw3y1l1y7SDhdg88oe8zTQHxX1RiZdlRcS86yPLMTxcBtEkf6D+Kbl3Y99SEw=="

public extension Duo where T1 == Branch, T2 == RemoteRepo {
	/// Push local branch changes to remote branch
	func push(credentials1: Credentials = .sshAgent) -> Result<(), NSError> {
		let (branch, remoteRepo) = self.value
		
		var credentials = Credentials
			.plaintext(username: "skulptorrr@gmail.com", password: "Sr@mom!Hl3dr:gi")
			
		
		var opts = pushOptions(credentials: credentials1)
		
		var a = remoteRepo.URL
		
		return remoteRepo.push(branchName: branch.name, options: &opts )
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
		
		//TODO: Can be optimized
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
			
			//TODO: Can be optimized
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

fileprivate func pushOptions(credentials: Credentials) -> git_push_options {
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

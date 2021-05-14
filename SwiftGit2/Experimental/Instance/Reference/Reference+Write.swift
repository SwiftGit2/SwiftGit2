//
//  Reference+Write.swift
//  SwiftGit2-OSX
//
//  Created by loki on 09.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

enum RefWriterError: Error {
	case NameHaveNoCorrectPrefix
	case BranchWasntFound
	case Unknown
}

public protocol ReferenceWriter : InstanceProtocol {
	func rename(_ newName: String) -> Result<Reference,Error>
}

extension Reference: ReferenceWriter {
	public func rename(_ newName: String) -> Result<Reference, Error> {
		rename(newName, force: false) // Or true?
	}
	
	/// If the force flag is not enabled, and there's already a reference with the given name, the renaming will fail.
	public func rename(_ newName: String, force: Bool) -> Result<Reference,Error> {
		var newReference: OpaquePointer? = nil
		
		let oid = try? self.commitOID.get()
		let messageToLog = "ReferenceWriter.rename: renaming: \(self.shortName) [OID: \(String(describing: oid ))] to \(newName)"
		let forceInt: Int32 = force ? 1 : 0
		
		return _result({ Reference(newReference!) }, pointOfFailure: "git_reference_rename") {
			newName.withCString { new_name in
				git_reference_rename(&newReference, self.pointer, new_name, forceInt, messageToLog)
			}
		}
	}
}

public extension Branch {
	///Need to use FULL name. ShortName will fail.
	func rename(to newName: String ) -> Result<Reference, Error> {
		if( !newName.starts(with: "refs/heads/") && !newName.starts(with: "refs/remotes/")) {
			return .failure(RefWriterError.NameHaveNoCorrectPrefix as Error)
		}
		
		return (self as! Reference).rename(newName)
	}
	
	func renameLocalUsingUnifiedName(to newName: String) -> Result<Reference, Error> {
		if self.isLocalBranch {
			return (self as! Reference).rename("refs/heads/\(newName)")
		}
		return .failure(RefWriterError.BranchWasntFound as Error)
	}
	
	func renameRemoteUsingUnifiedName(to newName: String ) -> Result<Reference, Error> {
		if self.isRemoteBranch {
			let sections = self.name.split(separator: "/")
			if sections.count < 3 {
				return .failure(RefWriterError.Unknown as Error)
			}
			let origin = sections[2]
			
			return  (self as! Reference).rename("refs/remotes/\(origin)/\(newName)")
		}
		
		return .failure(RefWriterError.BranchWasntFound as Error)
	}
	
	
	func delete() -> Result<(), Error> {
		return _result((), pointOfFailure: "git_branch_delete") {
			git_branch_delete(self.pointer)
		}
	}
}

public extension Repository {
	func rename(reference: String, to newName: String) -> Result<Reference, Error> {
		return self.reference(name: reference)
			.flatMap { $0.rename( newName) }
	}
	
	func rename(remote: String, to newName: String) -> Result<(), Error> {
		//TODO: return list of problems
		let problems = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
		defer {
			git_strarray_free(problems)
			problems.deallocate()
		}
		
		return _result((), pointOfFailure: "git_remote_rename") {
			remote.withCString { name in
				newName.withCString { new_name in
					git_remote_rename(problems, self.pointer, name, new_name)
				}
			}
		}
	}
}

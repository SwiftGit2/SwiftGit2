//
//  BranchInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public enum BranchLocation {
	case local
	case remote
}

public protocol Branch {
	var name 	 	: String 	{ get }
	var longName 	: String 	{ get }
	var commitOID	: OID? 		{ get }
}

extension Reference : Branch {
	public var name 	 	: String 	{ getName() }
	public var longName 	: String 	{ getLongName() }
	public var commitOID	: OID? 		{ getCommitOID() }
}

public extension Repository {
	func branches( _ location: BranchLocation) -> Result<[Branch], NSError> {
		switch location {
		case .local:		return references(withPrefix: "refs/heads/")
										.map { $0.compactMap { $0.asBranch } }
		case .remote: 		return references(withPrefix: "refs/remotes/")
										.map { $0.compactMap { $0.asBranch } }
		}
	}
}

private extension Reference {
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
	
	func getCommitOID() -> OID? {
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

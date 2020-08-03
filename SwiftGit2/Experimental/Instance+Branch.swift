//
//  Instance+Branch.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public enum BranchLocation {
	case local
	case remote
}

public struct InstanceBranch {
	let instance : Instance<Reference>
	
	var name 		: String { instance.name }
	var longName 	: String { instance.longName }
	var oid			: OID?	 { instance._oid }
	
	init?(instance : Instance<Reference>) {
		guard instance.isBranch || instance.isRemote
			else { return nil }
		self.instance = instance
	}
}


//extension Branch : InstanceType {
//	public func free(pointer: OpaquePointer) {
//		git_reference_free(pointer)
//	}
//}

////////////////////////////////////////////////////////////////////////////////////////////////////////

private extension Instance where Type == Reference {
	var name		: String {
		var namePointer: UnsafePointer<Int8>? = nil
		let success = git_branch_name(&namePointer, pointer)
		guard success == GIT_OK.rawValue else {
			return ""
		}
		return String(validatingUTF8: namePointer!) ?? ""
	}
	
	var longName : String { String(validatingUTF8: git_reference_name(pointer)) ?? "" }
	
	var _oid : OID? {
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


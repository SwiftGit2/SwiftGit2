//
//  ObjectInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public protocol ObjectProtocol : InstanceProtocol { }

public extension ObjectProtocol {
	var oid : OID { OID(git_object_id(pointer).pointee) }
}

public extension RepositoryInstance {
	func instanciate<ObjectType>(_ oid: OID) -> Result<ObjectType, NSError> where ObjectType : ObjectProtocol {
		var pointer: OpaquePointer? = nil
		var oid = oid.oid
		
		return _result({ ObjectType(pointer!) }, pointOfFailure: "git_object_lookup") {
			git_object_lookup(&pointer, self.pointer, &oid, gitType(for: ObjectType.self))
		}
	}

	private func gitType<ObjectType>(for type: ObjectType.Type) -> git_object_t where ObjectType : ObjectProtocol {
		switch type {
		case is CommitInstance.Type: 	return GIT_OBJECT_COMMIT
		case is Tree.Type:		return GIT_OBJECT_TREE
		case is Blob.Type:		return GIT_OBJECT_BLOB
		case is Tag.Type:		return GIT_OBJECT_TAG
			
		default:				return GIT_OBJECT_ANY
		}
	}

}

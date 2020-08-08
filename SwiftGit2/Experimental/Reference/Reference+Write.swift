//
//  Reference+Write.swift
//  SwiftGit2-OSX
//
//  Created by loki on 09.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public protocol ReferenceWriter : InstanceProtocol {
	func rename(_ newName: String) -> Result<Reference,NSError>
}

extension Reference: ReferenceWriter {
	public func rename(_ newName: String) -> Result<Reference,NSError> {
		var newReference: OpaquePointer? = nil

		return _result({ Reference(newReference!) }, pointOfFailure: "git_reference_rename") {
			newName.withCString { new_name in
				git_reference_rename(&newReference, self.pointer, new_name, 0, "ReferenceWriter.rename")
			}
		}
	}
}

public extension Repository {
	func rename(reference: String, to newName: String) -> Result<Reference, NSError> {
		return self.reference(name: reference)
			.flatMap { $0.rename( newName) }
	}
}

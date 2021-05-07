//
//  Repository+Diff.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 29.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public extension Repository {
	func hunksFrom(delta: Diff.Delta, options: DiffOptions? = nil) -> Result<[Diff.Hunk], Error> {
		let old = delta.oldFile != nil ? (try? blob(oid: delta.oldFile!.oid).get()) : nil
		let new = delta.newFile != nil ? (try? blob(oid: delta.newFile!.oid).get()) : nil
		
		return hunksBetweenBlobs(old: old, new: new, options: options)
	}
	
	func patchFrom(delta: Diff.Delta, options: DiffOptions? = nil, reverse: Bool = false) -> Result<Patch, Error> {
		
		var oldFile = delta.oldFile
		var newFile = delta.newFile
		
		loadBlobFor(file: &oldFile)
		loadBlobFor(file: &newFile)
		
		if reverse {
			return Patch.fromFiles(old: newFile, new: oldFile)
		}
		return Patch.fromFiles(old: oldFile, new: newFile)
	}
	
	func blob(oid: OID) -> Result<Blob, Error> {
		var oid = oid.oid
		var blob_pointer: OpaquePointer? = nil
		
		return _result({ Blob(blob_pointer!) }, pointOfFailure: "git_object_lookup") {
			git_object_lookup(&blob_pointer, self.pointer, &oid, GIT_OBJECT_BLOB)
		}
	}
}



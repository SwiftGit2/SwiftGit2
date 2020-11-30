//
//  Repository+Diff.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 29.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public extension Repository {
	func hunksFrom(delta: Diff.Delta, options: DiffOptions? = nil) -> Result<[Diff.Hunk], NSError> {
		let old = delta.oldFile != nil ? (try? blob(oid: delta.oldFile!.oid).get()) : nil
		let new = delta.newFile != nil ? (try? blob(oid: delta.newFile!.oid).get()) : nil
		
		return hunksBetweenBlobs(old: old, new: new, options: options)
	}
	
	func patchFrom(delta: Diff.Delta, options: DiffOptions? = nil, reverse: Bool = false) -> Result<Patch, NSError> {
		
		var oldFile = delta.oldFile
		var newFile = delta.newFile
		
		loadBlobFor(file: &oldFile)
		loadBlobFor(file: &newFile)
		
		if reverse {
			return Patch.fromFiles(old: newFile, new: oldFile)
		}
		return Patch.fromFiles(old: oldFile, new: newFile)
	}
	
	func blob(oid: OID) -> Result<Blob, NSError> {
		var oid = oid.oid
		var blob_pointer: OpaquePointer? = nil
		
		return _result({ Blob(blob_pointer!) }, pointOfFailure: "git_object_lookup") {
			git_object_lookup(&blob_pointer, self.pointer, &oid, GIT_OBJECT_BLOB)
		}
	}
}

public extension Repository {
	func hunksBetweenBlobs(old: Blob?, new: Blob?, options: DiffOptions?) -> Result<[Diff.Hunk],NSError>{
		var cb = DiffEachCallbacks()
		
		return _result( { cb.deltas.first?.hunks ?? [] }, pointOfFailure: "git_diff_blobs") {
			git_diff_blobs(old?.pointer, nil, new?.pointer, nil, options?.pointer, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
		}
	}
	
	func loadBlobFor(file: inout Diff.File?) {
		if let oid = file?.oid {
			file?.blob = try? blob(oid: oid).get()
		}
	}
	
}

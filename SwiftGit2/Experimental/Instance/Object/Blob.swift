//
//  Blob.swift
//  SwiftGit2-OSX
//
//  Created by loki on 30.11.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Blob : Object {
	public let pointer: OpaquePointer
	
	required public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_object_free(pointer)
	}
	
	public var oid: OID { OID(git_object_id(pointer).pointee) }
}

public extension Repository {
	func hunksBetweenBlobs(old: Blob?, new: Blob?, options: DiffOptions?) -> Result<[Diff.Hunk],Error>{
		var cb = DiffEachCallbacks()
		
		return _result( { cb.deltas.first?.hunks ?? [] }, pointOfFailure: "git_diff_blobs") {
			// git_diff_blobs(old_blob, old_as_path, new_blob, new_as_path, options, file_cb, binary_cb, hunk_cb, line_cb, payload)
			git_diff_blobs(old?.pointer, nil, new?.pointer, nil, options?.pointer, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
		}
	}
	
	func loadBlobFor(file: inout Diff.File?) {
		if let oid = file?.oid {
			file?.blob = try? blob(oid: oid).get()
		}
	}
	
}

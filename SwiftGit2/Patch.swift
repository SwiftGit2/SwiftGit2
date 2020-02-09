//
//  Patch.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Patch {
	let pointer: OpaquePointer
	
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	static func fromBlobs(old: Blob?, new: Blob?, options: DiffOptions? = nil) -> Result<Patch, NSError> {
		var patchPointer: OpaquePointer? = nil
		
		return _result({ Patch(patchPointer!) }, pointOfFailure: "git_patch_from_blobs") {
			git_patch_from_blobs(&patchPointer, old?.pointer, nil, new?.pointer, nil, options?.pointer)
		}
	}
	
	deinit {
		git_patch_free(pointer)
	}
	
	func asDelta() -> Diff.Delta {
		return Diff.Delta(git_patch_get_delta(pointer).pointee)
	}
	
	func asHunk(idx: Int = 0) -> Result<Diff.Hunk, NSError> {
		var hunkPointer: UnsafePointer<git_diff_hunk>? = nil
		var linesCount : Int = 0

		return _result( { Diff.Hunk(hunkPointer!.pointee) }, pointOfFailure: "git_patch_get_hunk") {
			git_patch_get_hunk(&hunkPointer, &linesCount, nil, idx)
		}
	}
	
	func asBuffer() -> Result<OpaquePointer, NSError> {
		let buff = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
		
		return _result(pointer, pointOfFailure: "git_patch_to_buf") {
			git_patch_to_buf(buff, pointer)
		}
	}
	
	func size() -> Int {
		return git_patch_size(pointer, 0, 0, 0)
	}
	
	func numNunks() -> Int {
		return git_patch_num_hunks(pointer)
	}
}

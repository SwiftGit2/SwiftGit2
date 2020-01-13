//
//  RepositoryDiff.swift
//  SwiftGit2
//
//  Created by Loki on 5/1/19.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension Repository {
	func diffTreeToTree(oldTree: Tree, newTree: Tree) -> Result<Diff, NSError> {
		var diff: OpaquePointer? = nil
		let result = git_diff_tree_to_tree(&diff, self.pointer, oldTree.pointer, newTree.pointer, nil)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_tree"))
		}
		
		return .success(Diff(diff!))
	}
	
	func diffTreeToIndex(tree: Tree) -> Result<Diff, NSError> {
		var diff: OpaquePointer? = nil
		let result = git_diff_tree_to_index(&diff, self.pointer, tree.pointer, nil /*index*/, nil /*options*/)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_index"))
		}
		
		return .success(Diff(diff!))
	}
	
	func diffIndexToWorkDir() -> Result<Diff, NSError> {
		var diff: OpaquePointer? = nil
		let result = git_diff_index_to_workdir(&diff, self.pointer, nil /* git_index */, nil /* git_diff_options */)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_index_to_workdir"))
		}
		
		return .success(Diff(diff!))
	}
	
	func diffTreeToWorkdir(tree: Tree) -> Result<Diff, NSError> {
		var diff: OpaquePointer? = nil
		let result = git_diff_tree_to_workdir(&diff, self.pointer, tree.pointer, nil)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_workdir"))
		}
		
		return .success(Diff(diff!))
	}
	
	func diffTreeToWorkdirWithIndex(tree: Tree) -> Result<Diff, NSError> {
		var diff: OpaquePointer? = nil
		let result = git_diff_tree_to_workdir_with_index(&diff, self.pointer, tree.pointer, nil)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_workdir_with_index"))
		}
		
		return .success(Diff(diff!))
	}
	
	func hunksFrom(delta: Diff.Delta) -> Result<[Diff.Hunk], NSError> {
		if delta.oldFile == nil {
			fatalError()
		}
		
		if delta.newFile == nil {
			fatalError()
		}
		
		guard let oldFile = delta.oldFile else { return .failure(NSError(gitError: 0, pointOfFailure: "no old file")) }
		guard let newFile = delta.newFile else { return .failure(NSError(gitError: 0, pointOfFailure: "no new file")) }
		//guard case let .success(OldBlob) = self.object(oldFile.oid).map({ $0 as? Blob })  else { return .failure(NSError(gitError: 0, pointOfFailure: "no object for old file")) }
		//guard case let .success(NewBlob) = self.object(newFile.oid).map({ $0 as? Blob })  else { return .failure(NSError(gitError: 0, pointOfFailure: "no object for new file")) }
		
		//guard let oldBlob = OldBlob else { return .failure(NSError(gitError: 0, pointOfFailure: "old blob not blob")) }
		//guard let newBlob = NewBlob else { return .failure(NSError(gitError: 0, pointOfFailure: "new blob not blob")) }
		
		return hunksBetweenBlobs(oid: oldFile.oid, oid2: newFile.oid)
		
		//return hunksBetween(blob: oldBlob, other: newBlob)
	}
	
}

extension Repository {
	func hunksBetweenBlobs(oid: OID, oid2: OID) -> Result<[Diff.Hunk],NSError>{
		var blob1_pointer: OpaquePointer? = nil
		var oid = oid.oid
		guard GIT_OK.rawValue == git_object_lookup(&blob1_pointer, self.pointer, &oid, GIT_OBJ_BLOB) else {
			let err = giterr_last()
			let message = String(cString: err!.pointee.message)
			fatalError(message)
		}
		defer { git_object_free(blob1_pointer) }
		
		var blob2_pointer: OpaquePointer? = nil
		var oid2 = oid2.oid
		guard GIT_OK.rawValue == git_object_lookup(&blob2_pointer, self.pointer, &oid2, GIT_OBJ_BLOB) else {
			fatalError()
		}
		defer { git_object_free(blob2_pointer) }
		
		
		var hunks = [Diff.Hunk]()
		var cb = DiffEachCallbacks() { delta in
			assert(hunks.isEmpty, "can't be more than one delta")
			hunks.append(contentsOf: delta.hunks)
		}
		
		let result = git_diff_blobs(blob1_pointer /*old_blob*/, nil /*old_as_path*/, blob2_pointer /*new_blob*/, nil /*new_as_path*/, nil /*options*/,
		cb.each_file_cb /*file_cb*/, nil /*binary_cb*/, cb.each_hunk_cb /*hunk_cb*/, cb.each_line_cb /*line_cb*/, &cb /*payload*/)
		
		if result == GIT_OK.rawValue {
			return .success(hunks)
		} else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_foreach"))
		}
		
	}
	func hunksBetween(blob: Blob, other: Blob) -> Result<[Diff.Hunk],NSError> {
		
		
		//let blob1 = self.oid
//		let optionsPointer = UnsafeMutablePointer<git_diff_options>.allocate(capacity: 1)
//		defer {
//			optionsPointer.deallocate()
//		}
//
//		let optionsResult = git_diff_init_options(optionsPointer, UInt32(GIT_STATUS_OPTIONS_VERSION))
//		guard optionsResult == GIT_OK.rawValue else {
//			fatalError("git_status_init_options")
//		}
		
		var hunks = [Diff.Hunk]()
		var cb = DiffEachCallbacks() { delta in
			assert(hunks.isEmpty, "can't be more than one delta")
			hunks.append(contentsOf: delta.hunks)
		}
		
		_ = blob.data.withUnsafeBytes { blobData in
			_ = other.data.withUnsafeBytes { otherData in
				guard let blob1 = blobData.baseAddress else { return }
				guard let blob2 = otherData.baseAddress else { return }
				//let result = git_diff_blobs(blob1 /*old_blob*/, nil /*old_as_path*/, blob2 /*new_blob*/, nil /*new_as_path*/, nil /*options*/,
				//	cb.each_file_cb /*file_cb*/, nil /*binary_cb*/, cb.each_hunk_cb /*hunk_cb*/, cb.each_line_cb /*line_cb*/, &cb /*payload*/)
//
				print(blob1, blob2)
//				if result == GIT_OK.rawValue {
//					return .success(hunks)
//				} else {
//					return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_foreach"))
//				}
			}
			
		}
		
		let result = git_diff_blobs(blob.pointer /*old_blob*/, nil /*old_as_path*/, other.pointer /*new_blob*/, nil /*new_as_path*/, nil /*options*/,
			cb.each_file_cb /*file_cb*/, nil /*binary_cb*/, cb.each_hunk_cb /*hunk_cb*/, cb.each_line_cb /*line_cb*/, &cb /*payload*/)
		
		if result == GIT_OK.rawValue {
			return .success(hunks)
		} else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_foreach"))
		}
	}
}

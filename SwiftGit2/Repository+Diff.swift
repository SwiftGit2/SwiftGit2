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
		
		
		var cb = DiffEachCallbacks()
		
		let result = git_diff_blobs(blob1_pointer /*old_blob*/, nil /*old_as_path*/, blob2_pointer /*new_blob*/, nil /*new_as_path*/, nil /*options*/,
		cb.each_file_cb /*file_cb*/, nil /*binary_cb*/, cb.each_hunk_cb /*hunk_cb*/, cb.each_line_cb /*line_cb*/, &cb /*payload*/)
		
		if result == GIT_OK.rawValue {
			if let delta = cb.deltas.first {
				return .success(delta.hunks)
			}
			return .success([])
		} else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_foreach"))
		}
		
	}

}

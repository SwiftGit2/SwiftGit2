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
		let old = delta.oldFile != nil ? (try? blob(oid: delta.oldFile!.oid).get()) : nil
		let new = delta.newFile != nil ? (try? blob(oid: delta.newFile!.oid).get()) : nil
		
		return hunksBetweenBlobs(old: old, new: new)
	}
	
}

extension Repository {
	func hunksBetweenBlobs(old: Blob?, new: Blob?) -> Result<[Diff.Hunk],NSError>{
		var cb = DiffEachCallbacks()
		
		return _result( { cb.deltas.first?.hunks ?? [] }, pointOfFailure: "git_diff_blobs") {
			git_diff_blobs(old?.pointer, nil, new?.pointer, nil, nil, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
		}
	}

}

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

class DiffEachCallbacks {
	var deltas = [Diff.Delta]()
	
	let each_file_cb : git_diff_file_cb = { delta, progress, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.file(delta: Diff.Delta(delta.unsafelyUnwrapped.pointee), progress: progress)
		
		return 0
	}
	
	let each_line_cb : git_diff_line_cb = { delta, hunk, line, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.line(line: Diff.Line(line.unsafelyUnwrapped.pointee))
		
		return 0
	}
	
	let each_hunk_cb : git_diff_hunk_cb = { delta, hunk, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.hunk(hunk: Diff.Hunk(hunk.unsafelyUnwrapped.pointee))

		return 0
	}
		
	private func file(delta: Diff.Delta, progress: Float32) {
		deltas.append(delta)
	}
	
	private func hunk(hunk: Diff.Hunk) {
		guard let _ = deltas.last 				else { assert(false, "can't add hunk before adding delta"); return }
		
		deltas[deltas.count - 1].hunks.append(hunk)
	}
	
	private func line(line: Diff.Line) {
		guard let _ = deltas.last 				else { assert(false, "can't add line before adding delta"); return }
		guard let _ = deltas.last?.hunks.last 	else { assert(false, "can't add line before adding hunk"); return }
		
		let deltaIdx = deltas.count - 1
		let hunkIdx = deltas[deltaIdx].hunks.count - 1
		
		deltas[deltaIdx].hunks[hunkIdx].lines.append(line)
	}
}

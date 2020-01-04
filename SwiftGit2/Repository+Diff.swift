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
		guard let oldFile = delta.oldFile else { return .failure(NSError(gitError: 0, pointOfFailure: "no old file")) }
		guard let newFile = delta.newFile else { return .failure(NSError(gitError: 0, pointOfFailure: "no new file")) }
		guard case let .success(OldBlob) = self.object(oldFile.oid).map({ $0 as? Blob })  else { return .failure(NSError(gitError: 0, pointOfFailure: "no object for old file")) }
		guard case let .success(NewBlob) = self.object(newFile.oid).map({ $0 as? Blob })  else { return .failure(NSError(gitError: 0, pointOfFailure: "no object for new file")) }
		
		guard let oldBlob = OldBlob else { return .failure(NSError(gitError: 0, pointOfFailure: "old blob not blob")) }
		guard let newBlob = NewBlob else { return .failure(NSError(gitError: 0, pointOfFailure: "new blob not blob")) }
		
		
		return newBlob.hunksDiffWith(blob: oldBlob)
	}
	
}

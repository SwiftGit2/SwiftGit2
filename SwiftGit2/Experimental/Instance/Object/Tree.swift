//
//  Tree.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Tree : InstanceProtocol {
	public var pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_tree_free(pointer)
	}
}

//High level func's
public extension Repository {
	func headDiff() -> Result<[Diff], Error> {
		let set = XR.Set(with: self)
		
		// diff with all parents
		return set.with( set[Repository.self].headCommit() )        // assigns set[Commit.self] to refer HEAD commit
			.flatMap { $0.with( $0[Commit.self].getTree()) }        // assigns set[Tree.self] to refer Tree of HEAD commit
			.flatMap { $0.with( $0[Commit.self]                     // assigns set[[Tree].self] to refer parent trees of HEAD commit
									.parents()
									.flatMap { $0.flatMap { $0.getTree() } }
							   ) }
			//call diffTreeToTree for each parent tree
			.flatMap { set in set[[Tree].self].flatMap { parent in set[Repository.self].diffTreeToTree(oldTree: parent, newTree: set[Tree.self]) } }
		// diff with first parent would be
		//  .flatMap { $0[Repository.self].diffTreeToTree(oldTree: $0[[Tree].self][0], newTree: $0[Tree.self]) }
	}
}

//Low level func's
public extension Repository {
	func diffTreeToTree(oldTree: Tree, newTree: Tree, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
		var diff: OpaquePointer? = nil
		let result = git_diff_tree_to_tree(&diff, self.pointer, oldTree.pointer, newTree.pointer, &options.diff_options)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_tree"))
		}
		
		return .success(Diff(diff!))
	}
	
	func diffTreeToIndex(tree: Tree, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
		var diff: OpaquePointer? = nil
		let result = git_diff_tree_to_index(&diff, self.pointer, tree.pointer, nil /*index*/, &options.diff_options)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_index"))
		}
		
		return .success(Diff(diff!))
	}
}

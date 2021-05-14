//
//  RevisionWalker.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//
import Foundation
import Clibgit2

public extension Repository {
	/// Method needed to collect not pushed or not pulled commits
	func getChangedCommits(branchToHide: String, branchToPush: String) -> Result<[Commit], Error> {
		return walk(hideRef: branchToHide, pushRef: branchToPush)
	}
}


extension Repository {	
	func walk(hideRef: String, pushRef: String) -> Result<[Commit], Error> {
		let walker = RevisionWalker(repo: self, hideRef: hideRef, pushRef: pushRef)
		var result: [Result<Commit, Error>] = []
		
		for elem in walker {
			result.append(elem)
		}
		
		return result.flatMap { $0 }
	}
}

fileprivate class RevisionWalker: IteratorProtocol, Sequence {
	public typealias Iterator = RevisionWalker
	public typealias Element = Result<Commit, Error>
	let repo: Repository
	private var pointer: OpaquePointer?
	
	///localBranchToHide: "refs/heads/master"
	///remoteBranchToPush: "refs/remotes/origin/master"
	init(repo: Repository, hideRef: String, pushRef: String) {
		self.repo = repo
		git_revwalk_new(&pointer, repo.pointer)
		git_revwalk_hide_ref(pointer, hideRef);
		git_revwalk_push_ref(pointer, pushRef);
	}

	init(repo: Repository, root: git_oid) {
		self.repo = repo
		
		var oid = root
		
		git_revwalk_new(&pointer, repo.pointer)
		git_revwalk_sorting(pointer, GIT_SORT_TOPOLOGICAL.rawValue)
		git_revwalk_sorting(pointer, GIT_SORT_TIME.rawValue)
		git_revwalk_push(pointer, &oid)
	}

	deinit {
		git_revwalk_free(self.pointer)
	}

	public func next() -> Element? {
		switch _next() {
		case let .error(error):
			return Result.failure(error)
			
		case .over:
			return nil
			
		case .okay(let oid):
			return Duo(oid, repo).commit()
		}
	}
	
	private func _next() -> Next {
		var oid = git_oid()

		switch git_revwalk_next(&oid, pointer) {
		case GIT_ITEROVER.rawValue:
			return .over
		case GIT_OK.rawValue:
			return .okay(OID(oid))
		default:
			return .error(NSError(gitError: GIT_ERROR.rawValue, pointOfFailure: "git_revwalk_next"))
		}
	}
}

private enum Next {
	case over
	case okay(OID)
	case error(Error)
}

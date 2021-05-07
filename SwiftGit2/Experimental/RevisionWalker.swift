//
//  RevisionWalker.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//
import Foundation
import Clibgit2

public class RevisionWalker: IteratorProtocol, Sequence { // Earlier CommitIterator_OLD
	public typealias Iterator = RevisionWalker
	public typealias Element = Result<Commit, Error>
	let repo: Repository
	private var revisionWalker: OpaquePointer?

	private enum Next {
		case over
		case okay
		case error(Error)

		init(_ result: Int32, name: String) {
			switch result {
			case GIT_ITEROVER.rawValue:
				self = .over
			case GIT_OK.rawValue:
				self = .okay
			default:
				self = .error(NSError(gitError: result, pointOfFailure: name))
			}
		}
	}
	
	///localBranchToHide: "refs/heads/master"
	///remoteBranchToPush: "refs/remotes/origin/master"
	init(repo: Repository, localBranchToHide: String, remoteBranchToPush: String) {
		self.repo = repo
		git_revwalk_new(&revisionWalker, repo.pointer)
		git_revwalk_hide_ref(revisionWalker, localBranchToHide);
		git_revwalk_push_ref(revisionWalker, remoteBranchToPush);
	}

	init(repo: Repository, root: git_oid) {
		self.repo = repo
		setupRevisionWalker(root: root)
	}

	deinit {
		git_revwalk_free(self.revisionWalker)
	}

	private func setupRevisionWalker(root: git_oid) {
		var oid = root
		git_revwalk_new(&revisionWalker, repo.pointer)
		git_revwalk_sorting(revisionWalker, GIT_SORT_TOPOLOGICAL.rawValue)
		git_revwalk_sorting(revisionWalker, GIT_SORT_TIME.rawValue)
		git_revwalk_push(revisionWalker, &oid)
	}

	public func next() -> Element? {
		var oid = git_oid()
		let revwalkGitResult = git_revwalk_next(&oid, revisionWalker)
		
		let nextResult = Next(revwalkGitResult, name: "git_revwalk_next")
		
		switch nextResult {
		case let .error(error):
			return Result.failure(error)
			
		case .over:
			return nil
			
		case .okay:
			return Duo( (OID(oid), repo) ).commit()
		}
	}
}

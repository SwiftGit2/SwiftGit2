//
// Created by Arnon Keereena on 4/28/17.
// Copyright (c) 2017 GitHub, Inc. All rights reserved.
//

import Result
import libgit2

public class CommitIterator: IteratorProtocol {
	public typealias Element = Result<Commit, NSError>
	let repo: Repository
	private var oid: git_oid
	private var revisionWalker: OpaquePointer? = nil

	private enum Next {
		case over
		case ok
		case error(NSError)

		init(_ result: Int32, name: String) {
			switch result {
			case GIT_ITEROVER.rawValue:
				self = .over
			case GIT_OK.rawValue:
				self = .ok
			default:
				self = .error(NSError(gitError: result, pointOfFailure: name))
			}
		}
	}

	init(repo: Repository, branch: Branch) {
		self.repo = repo
		self.oid = branch.oid.oid
		setupRevisionWalker()
	}

	deinit {
		git_revwalk_free(self.revisionWalker)
	}

	private func setupRevisionWalker() {
		git_revwalk_new(&revisionWalker, repo.pointer)
		git_revwalk_sorting(revisionWalker, GIT_SORT_TOPOLOGICAL.rawValue)
		git_revwalk_sorting(revisionWalker, GIT_SORT_TIME.rawValue)
		git_revwalk_push(revisionWalker, &oid)
	}

	private func next(withName name: String, from result: Int32) -> Next {
		if result == GIT_OK.rawValue || result == GIT_ITEROVER.rawValue {
			return Next(result, name: name)
		} else {
			return Next.error(NSError(gitError: result, pointOfFailure: name))
		}
	}

	public func next() -> Element? {
		var unsafeCommit: OpaquePointer? = nil
		let revwalkGitResult = git_revwalk_next(&oid, revisionWalker)
		let nextResult = next(withName: "git_revwalk_next", from: revwalkGitResult)
		if case let .error(error) = nextResult {
			return Result.failure(error)
		} else if case .over = nextResult {
			return nil
		}
		guard git_commit_lookup(&unsafeCommit, repo.pointer, &oid) == GIT_OK.rawValue,
		      let unwrapCommit = unsafeCommit else {
			return nil
		}
		let result: Element = Result.success(Commit(unwrapCommit))
		git_commit_free(unsafeCommit)
		return result
	}
}

//
// Created by Arnon Keereena on 4/28/17.
// Copyright (c) 2017 GitHub, Inc. All rights reserved.
//

import Result
import libgit2

public class CommitIterator: IteratorProtocol, Sequence {
	public typealias Iterator = CommitIterator
	public typealias Element = Result<Commit, NSError>
	let repo: Repository
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
		case .ok:
			var unsafeCommit: OpaquePointer? = nil
			let lookupGitResult = git_commit_lookup(&unsafeCommit, repo.pointer, &oid)
			guard lookupGitResult == GIT_OK.rawValue,
			      let unwrapCommit = unsafeCommit else {
				return Result.failure(NSError(gitError: lookupGitResult, pointOfFailure: "git_commit_lookup"))
			}
			let result: Element = Result.success(Commit(unwrapCommit))
			git_commit_free(unsafeCommit)
			return result
		}
	}
	
	public func makeIterator() -> CommitIterator {
		return self
	}
	
	public private(set) var underestimatedCount: Int = 0
	public func map<T>(_ transform: (Result<Commit, NSError>) throws -> T) rethrows -> [T] {
		var new: [T] = []
		for item in self {
			new = new + [try transform(item)]
		}
		return new
	}
	
	public func filter(_ isIncluded: (Result<Commit, NSError>) throws -> Bool) rethrows -> [Result<Commit, NSError>] {
		var new: [Result<Commit, NSError>] = []
		for item in self {
			if try isIncluded(item) {
				new = new + [item]
			}
		}
		return new
	}
	
	public func forEach(_ body: (Result<Commit, NSError>) throws -> Void) rethrows {
		for item in self {
			try body(item)
		}
	}
	
	private func notImplemented(functionName: Any) {
		assert(false, "CommitIterator does not implement \(functionName)")
	}
	private init(repo: Repository) {
		self.repo = repo
	}
	
	public func dropFirst(_ n: Int) -> AnySequence<Iterator.Element> {
		notImplemented(functionName: self.dropFirst)
		return AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }
	}
	
	public func dropLast(_ n: Int) -> AnySequence<Iterator.Element> {
		notImplemented(functionName: self.dropLast)
		return AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }
	}
	
	public func drop(while predicate: (Result<Commit, NSError>) throws -> Bool) rethrows -> AnySequence<Iterator.Element> {
		notImplemented(functionName: self.drop)
		return AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }
	}
	
	public func prefix(_ maxLength: Int) -> AnySequence<Iterator.Element> {
		notImplemented(functionName: "prefix(_ maxLength:")
		return AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }
	}
	
	public func prefix(while predicate: (Result<Commit, NSError>) throws -> Bool) rethrows -> AnySequence<Iterator.Element> {
		notImplemented(functionName: "prefix(with predicate:")
		return AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }
	}
	
	public func suffix(_ maxLength: Int) -> AnySequence<Iterator.Element> {
		notImplemented(functionName: self.suffix)
		return AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }
	}
	
	public func split(maxSplits: Int, omittingEmptySubsequences: Bool, whereSeparator isSeparator: (Result<Commit, NSError>) throws -> Bool) rethrows -> [AnySequence<Iterator.Element>] {
		notImplemented(functionName: self.split)
		return [AnySequence<Iterator.Element> { return CommitIterator(repo: self.repo) }]
	}
	
}

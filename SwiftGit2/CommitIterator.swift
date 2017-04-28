//
// Created by Arnon Keereena on 4/28/17.
// Copyright (c) 2017 GitHub, Inc. All rights reserved.
//

import Result
import libgit2

public class CommitIterator: IteratorProtocol {
    public typealias Element = Result<Commit, NSError>
    var repo: Repository
    var branch: Branch
    var revisionWalker: OpaquePointer? = nil
    var oid: git_oid
    private var unsafeCommit: OpaquePointer? = nil
    
    public init(repo: Repository, branch: Branch) {
        self.repo = repo
        self.branch = branch
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
    
    private func result(withName name: String, from result: Int32) -> (stop: Bool, error: NSError?) {
        guard result == GIT_OK.rawValue else {
            if result == GIT_ITEROVER.rawValue {
                return (stop: true, error: nil)
            } else {
                return (stop: false, error: NSError(gitError: result, pointOfFailure: name))
            }
        }
        return (stop: false, error: nil)
    }
    
    public func next() -> Element? {
        let revwalkGitResult = git_revwalk_next(&self.oid, self.revisionWalker)
        let revwalkResult = result(withName: "git_revwalk_next", from: revwalkGitResult)
        if revwalkResult.stop {
            return nil
        } else if let error = revwalkResult.error {
            return Result.failure(error)
        }
        let lookupGitResult = git_commit_lookup(&self.unsafeCommit, self.repo.pointer, &self.oid)
        let lookupResult = result(withName: "git_commit_lookup", from: lookupGitResult)
        if lookupResult.stop {
            return nil
        } else if let error = lookupResult.error {
            return Result.failure(error)
        }
        guard let commit = unsafeCommit else {
            return nil
        }
        git_commit_free(unsafeCommit)
        return Result.success(Commit(commit))
    }
}
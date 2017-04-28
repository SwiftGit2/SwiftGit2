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
    
    private func error(from gitCommands: [(key: String, value: () -> Int32)]) -> NSError? {
        // TODO: Make a  flatMap command that stops on first nil
        let errors: [NSError] = gitCommands.flatMap {
            let result = $0.value()
            return result == GIT_OK.rawValue ? nil : NSError(gitError: result, pointOfFailure: $0.key)
        }
        if errors.count > 0 {
            return errors.first!
        } else {
            return nil
        }
    }
    
    public func next() -> Element? {
        var unsafeCommit: OpaquePointer? = nil
        let gitCommands = [
            (key: "git_revwalk_next", value: { return git_revwalk_next(&self.oid, self.revisionWalker) }),
            (key: "git_commit_lookup", value: { return git_commit_lookup(&unsafeCommit, self.repo.pointer, &self.oid) })
        ]
        if let error = error(from: gitCommands) {
            return Result.failure(error)
        } else {
            guard let commit = unsafeCommit else {
                return nil
            }
            git_commit_free(unsafeCommit)
            return Result.success(Commit(commit))
        }
    }
}
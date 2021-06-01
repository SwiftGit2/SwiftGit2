//
//  Tree.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Tree: InstanceProtocol {
    public var pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_tree_free(pointer)
    }
}

public extension Tree {
    var oid : OID { OID(git_tree_id(self.pointer).pointee) }
}

// High level func's
public extension Repository {
    func headDiff() -> Result<[Diff], Error> {
        let set = XR.Set(with: self)

        return checkHistorySituation()
            .flatMap { situation -> Result<[Diff], Error> in
                switch situation {
                case .zero: // Logic for 0 commits in history
                    return .success([])

                case .oneCommit: // Logic for 1 commit in history
                    let repo = self
                    return self.headCommit().flatMap { $0.tree() }
                        .flatMap { repo.diffTreeToTree(oldTree: $0, newTree: nil) }
                        .map { [$0] }

                case .manyCommits: // Logic for 2 and more commits in history
                    return set.with(set[Repository.self].headCommit()) // assigns set[Commit.self] to refer HEAD commit
                        .flatMap { $0.with($0[Commit.self].tree()) } // assigns set[Tree.self] to refer Tree of HEAD commit
                        .flatMap { $0.with($0[Commit.self] // assigns set[[Tree].self] to refer parent trees of HEAD commit
                                .parents()
                                .flatMap { $0.flatMap { $0.tree() } }) }
                        // call diffTreeToTree for each parent tree
                        .flatMap { set in set[[Tree].self].flatMap { parent in set[Repository.self].diffTreeToTree(oldTree: parent, newTree: set[Tree.self]) }
                        }
                }
            }
    }

    fileprivate func checkHistorySituation() -> Result<HistorySituation, Error> {
        if let headCommit = try? self.headCommit().get() {
            return headCommit.parents()
                .map { $0.count == 0 ? HistorySituation.oneCommit : .manyCommits }
        }

        return .success(HistorySituation.zero)
    }

    fileprivate enum HistorySituation {
        case zero
        case oneCommit
        case manyCommits
    }
}

// Low level func's
public extension Repository {
    func diffTreeToTree(oldTree: Tree, newTree: Tree?, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
        var diff: OpaquePointer?
        let result = git_diff_tree_to_tree(&diff, pointer, oldTree.pointer, newTree?.pointer ?? nil, &options.diff_options)

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_tree"))
        }

        return .success(Diff(diff!))
    }

    func diffTreeToIndex(tree: Tree, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
        var diff: OpaquePointer?
        let result = git_diff_tree_to_index(&diff, pointer, tree.pointer, nil /* index */, &options.diff_options)

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_index"))
        }

        return .success(Diff(diff!))
    }
}

//
//  Repository+Merge.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import Foundation

public extension Repository {
    func mergeBase(one: OID, two: OID) -> Result<OID, Error> {
        var out = git_oid()

        return git_try("git_merge_base") {
            var one_ = one.oid
            var two_ = two.oid
            return git_merge_base(&out, self.pointer, &one_, &two_)
        }.map { OID(out) }
    }

    func merge(our: Tree, their: Tree, ancestor: Tree) -> Result<Index, Error> {
        var options = MergeOptions()
        var indexPointer: OpaquePointer?

        return git_try("git_merge_trees") {
            git_merge_trees(&indexPointer, self.pointer, ancestor.pointer, our.pointer, their.pointer, &options.merge_options)
        }.map { Index(indexPointer!) }
    }

    func merge(our: Commit, their: Commit) -> Result<Index, Error> {
        var options = MergeOptions()
        var indexPointer: OpaquePointer?

        return git_try("git_merge_commits") {
            git_merge_commits(&indexPointer, self.pointer, our.pointer, their.pointer, &options.merge_options)
        }.map { Index(indexPointer!) }
    }

    @available(*, deprecated, message: "Commit messaged should be: Fast Forward MERGE theirReference.nameAsReference -> ourReference.nameAsReference ")
    func mergeAndCommit(our: Commit, their: Commit, signature: Signature) -> Result<Commit, Error> {
        return merge(our: our, their: their)
            .flatMap { index in
                Duo(index, self)
                    .commit(message: "TAO_MERGE", signature: signature)
            }
    }

    func mergeAnalysis(_ target: FetchTarget) -> Result<MergeAnalysis, Error> {
        switch target {
        case .HEAD:
            return HEAD()
                .flatMap { $0.asBranch() }
                .flatMap { self.mergeAnalysis(.branch($0)) } // fancy recursion
        case let .branch(branch):
            return branch.upstream()
                .flatMap { $0.targetOID }
                .flatMap { self.annotatedCommit(oid: $0) }
                .flatMap { self.mergeAnalysis(their_head: $0) }
        }
    }

    // Analyzes the given branch(es) and determines the opportunities for merging them into the HEAD of the repository.
    func mergeAnalysis(their_head: AnnotatedCommit) -> Result<MergeAnalysis, Error> {
        var anal = git_merge_analysis_t.init(0)
        var pref = git_merge_preference_t.init(0)
        var their_heads: OpaquePointer? = their_head.pointer

        return git_try("git_merge_analysis") {
            git_merge_analysis(&anal, &pref, self.pointer, &their_heads, 1)
        }.map { MergeAnalysis(rawValue: anal.rawValue) }
    }
}

public class AnnotatedCommit: InstanceProtocol {
    public var pointer: OpaquePointer
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_annotated_commit_free(pointer)
    }
}

public extension Repository {
    func annotatedCommit(oid: OID) -> Result<AnnotatedCommit, Error> {
        var pointer: OpaquePointer?
        var _oid = oid.oid

        return _result({ AnnotatedCommit(pointer!) }, pointOfFailure: "git_annotated_commit_lookup") {
            git_annotated_commit_lookup(&pointer, self.pointer, &_oid)
        }
    }
}

public struct MergeAnalysis: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32

    public static let none = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_NONE.rawValue) // No merge is possible.  (Unused.)
    public static let normal = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_NORMAL.rawValue) // A "normal" merge; both HEAD and the given merge input have diverged from their common ancestor. The divergent commits must be merged.
    public static let upToDate = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_UP_TO_DATE.rawValue) // All given merge inputs are reachable from HEAD, meaning the repository is up-to-date and no merge needs to be performed.
    public static let fastForward = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_FASTFORWARD.rawValue) // The given merge input is a fast-forward from HEAD and no merge needs to be performed. Instead, the client can check out the given merge input.
    public static let unborn = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_UNBORN.rawValue) // The HEAD of the current repository is "unborn" and does not point to a valid commit. No merge can be performed, but the caller may wish to simply set HEAD to the target commit(s).
}

public struct MergePreference: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32

    public static let none = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_NONE.rawValue) // No configuration was found that suggests a preferred behavior for merge.
    public static let noFastForward = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_NO_FASTFORWARD.rawValue) // There is a merge.ff=false configuration setting, suggesting that the user does not want to allow a fast-forward merge.
    public static let fastForwardOnly = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_FASTFORWARD_ONLY.rawValue) // There is a merge.ff=only configuration setting, suggesting that the user only wants fast-forward merges.
}

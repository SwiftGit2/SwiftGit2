//
//  Repository+Merge.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Repository {
    func merge(our: Commit, their: Commit ) -> Result<Index, Error> {
        var options = MergeOptions()
        var indexPointer : OpaquePointer? = nil
        
        return _result( { Index(indexPointer!) } , pointOfFailure: "git_merge_commits") {
            git_merge_commits(&indexPointer, self.pointer , our.pointer, their.pointer, &options.merge_options)
        }
    }
    
    func mergeAndCommit(our: Commit, their: Commit, signature: Signature) -> Result<Commit, Error> {
        return merge(our: our, their: their)
            .flatMap { index in
                Duo(index,self)
                    .commit(message: "TAO_MERGE", signature: signature )
            }
    }
    
    func mergeAnalysis() -> Result<MergeAnalysis, Error> {
        HEAD()
            .flatMap { $0.asBranch() }
            .flatMap { $0.upstream() }
            .flatMap { $0.targetOID }
            .flatMap { self.annotatedCommit(oid: $0) }
            .flatMap { self.mergeAnalysis(their_head: $0) }
    }
    
    // Analyzes the given branch(es) and determines the opportunities for merging them into the HEAD of the repository.
    func mergeAnalysis(their_head: AnnotatedCommit) -> Result<MergeAnalysis, Error> {
        var anal = git_merge_analysis_t.init(0)
        var pref = git_merge_preference_t.init(0)
        var their_heads : OpaquePointer? = their_head.pointer
        
        return git_try("git_merge_analysis") {
            git_merge_analysis(&anal, &pref, self.pointer, &their_heads, 1)
        }.map { MergeAnalysis(rawValue: anal.rawValue) }
    }
}

public class AnnotatedCommit : InstanceProtocol {
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
        var pointer: OpaquePointer? = nil
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
    
    public static let none             = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_NONE.rawValue)          // No merge is possible.  (Unused.)
    public static let normal           = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_NORMAL.rawValue)        // A "normal" merge; both HEAD and the given merge input have diverged from their common ancestor. The divergent commits must be merged.
    public static let upToDate         = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_UP_TO_DATE.rawValue)    // All given merge inputs are reachable from HEAD, meaning the repository is up-to-date and no merge needs to be performed.
    public static let fastForward      = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_FASTFORWARD.rawValue)   // The given merge input is a fast-forward from HEAD and no merge needs to be performed. Instead, the client can check out the given merge input.
    public static let unborn           = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_UNBORN.rawValue)        // The HEAD of the current repository is "unborn" and does not point to a valid commit. No merge can be performed, but the caller may wish to simply set HEAD to the target commit(s).
}

public struct MergePreference: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    public let rawValue: UInt32
    
    public static let none             = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_NONE.rawValue)    // No configuration was found that suggests a preferred behavior for merge.
    public static let noFastForward    = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_NO_FASTFORWARD.rawValue)  // There is a merge.ff=false configuration setting, suggesting that the user does not want to allow a fast-forward merge.
    public static let fastForwardOnly  = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_FASTFORWARD_ONLY.rawValue)    // There is a merge.ff=only configuration setting, suggesting that the user only wants fast-forward merges.
}

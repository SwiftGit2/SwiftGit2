//
//  RevisionWalker.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//
import Clibgit2
import Foundation
import Essentials

enum RevwalkTarget {
    case PushRange(String)
}

public extension Repository {
    func commitsToPush(_ target: FetchTarget) -> R<[Commit]> {
        switch target {
        case .HEAD:
            return HEAD()
                | { $0.asBranch() }
                | { self.commitsToPush(.branch($0)) } // very fancy recursion
        case let .branch(branch):
            return branch.upstream()
                | { $0.nameAsReference }
                | { commitsToPush(branchToHide: branch.nameAsReference, branchToPush: $0) }
        }
    }
    /// Method needed to collect not pushed or not pulled commits
    func commitsToPush(branchToHide: String, branchToPush: String) -> Result<[Commit], Error> {
        return walk(hideRef: branchToHide, pushRef: branchToPush)
    }
}

extension Repository {
    func walk(hideRef: String, pushRef: String) -> Result<[Commit], Error> {
        let walker = RevisionWalker(repo: self, hideRef: hideRef, pushRef: pushRef)
        return Array(walker).flatMap { $0 }
    }
}

internal class Revwalk : InstanceProtocol, ResultIterator {
    typealias Success = OID
    
    var pointer: OpaquePointer
    
    required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    static func new(in repo: Repository) -> R<Revwalk> {
        git_instance(of: Revwalk.self, "git_revwalk_new") { git_revwalk_new(&$0, repo.pointer) }
    }
    
    func push(range: String) -> R<Revwalk> {
        git_try("git_revwalk_push_range") { git_revwalk_push_range(pointer, range) } | { self }
    }
    
    func push(ref: String) -> R<Revwalk> {
        git_try("git_revwalk_push_ref") { git_revwalk_push_ref(pointer, ref) } | { self }
    }
    
    func hide(oid: OID) -> R<Revwalk> {
        var oid = oid.oid
        return git_try("git_revwalk_hide") { git_revwalk_hide(pointer, &oid) } | { self }
    }
    
    func hide(ref: String) -> R<Revwalk> {
        return git_try("git_revwalk_hide") { git_revwalk_hide_ref(pointer, ref) } | { self }
    }
    
    // calls by all() in ResultIterator
    func next() -> Result<OID?, Error> {
        var oid = git_oid()

        switch git_revwalk_next(&oid, pointer) {
        case GIT_ITEROVER.rawValue:
            return .success(nil)
        case GIT_OK.rawValue:
            return .success(OID(oid))
        default:
            return .failure(NSError(gitError: GIT_ERROR.rawValue, pointOfFailure: "git_revwalk_next"))
        }
    }

    
}

private class RevisionWalker: IteratorProtocol, Sequence {
    public typealias Iterator = RevisionWalker
    public typealias Element = Result<Commit, Error>
    let repo: Repository
    private var pointer: OpaquePointer?

    init(repo: Repository, target: FetchTarget) {
        self.repo = repo
        git_revwalk_new(&pointer, repo.pointer)
    }
    
    /// localBranchToHide: "refs/heads/master"
    /// remoteBranchToPush: "refs/remotes/origin/master"
    init(repo: Repository, hideRef: String, pushRef: String) {
        self.repo = repo
        git_revwalk_new(&pointer, repo.pointer)
        git_revwalk_hide_ref(pointer, hideRef)
        git_revwalk_push_ref(pointer, pushRef)
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

        case let .okay(oid):
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

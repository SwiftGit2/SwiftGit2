//
//  RepositoryInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Repository: InstanceProtocol {
    public var pointer: OpaquePointer

    public var directoryURL: Result<URL, Error> {
        if let pathPointer = git_repository_workdir(pointer) {
            return .success(URL(fileURLWithPath: String(cString: pathPointer), isDirectory: true))
        }

        return .failure(RepositoryError.FailedToGetRepoUrl as Error)
    }

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_repository_free(pointer)
    }
}

extension Repository: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch directoryURL {
        case let .success(url):
            return "Git2.Repository: " + url.path
        case let .failure(error):
            return "Git2.Repository: ERROR " + error.localizedDescription
        }
    }
}

// Remotes
public extension Repository {
    //TEST
    func blobCreateFromDisk(path: String) -> R<OID> {
        var oid = git_oid()
        
        return _result({ OID(oid) }, pointOfFailure: "git_blob_create_from_disk") {
            path.withCString{ path1 in
                Clibgit2.git_blob_create_from_disk(&oid, self.pointer, path1)
            }
        }
    }
    
    var childrenURLs : R<[URL]> {
        let url = self.directoryURL
        let paths = submodules().map { $0.map { $0.path } }
        return combine(url, paths).map { url, paths in paths.map { url.appendingPathComponent($0) } }
    }

    func getRemoteFirst() -> Result<Remote, Error> {
        return getRemotesNames()
            .flatMap { arr -> Result<Remote, Error> in
                if let first = arr.first {
                    return self.remoteRepo(named: first)
                }
                return .failure(WTF("can't get RemotesNames"))
            }
    }

    func getAllRemotes() -> Result<[Remote], Error> {
        return getRemotesNames()
            .flatMap { $0.flatMap { self.remoteRepo(named: $0) } }
    }

    private func getRemotesNames() -> Result<[String], Error> {
        var strarray = git_strarray()

        return _result({ strarray.map { $0 } }, pointOfFailure: "git_remote_list") {
            git_remote_list(&strarray, self.pointer)
        }
    }
}

public enum BranchBase { 
    case head
    case commit(Commit)
    case branch(Branch)
}

public extension Repository {
    func createReference(name: String, oid: OID, force: Bool, reflog: String)-> R<Reference> {
        var oid = oid.oid

        return git_instance(of: Reference.self, "git_reference_create") { pointer in
            git_reference_create(&pointer, self.pointer, name, &oid, force ? 1 : 0, reflog)
        }
    }
    
    func createBranch(from base: BranchBase, name: String, checkout: Bool) -> Result<Reference, Error> {
        switch base {
        case .head: return headCommit().flatMap { createBranch(from: $0, name: name, checkout: checkout) }
        case let .commit(c): return createBranch(from: c, name: name, checkout: checkout)
        case let .branch(b): return Duo(b, self).commit().flatMap { c in createBranch(from: c, name: name, checkout: checkout) }
        }
    }
    
    func branchLookup(name: String) -> R<Branch>{
        reference(name: name)
            .flatMap{ $0.asBranch() }
    }

    func headCommit() -> Result<Commit, Error> {
        var oid = git_oid()

        return _result({ oid }, pointOfFailure: "git_reference_name_to_id") {
            git_reference_name_to_id(&oid, self.pointer, "HEAD")
        }
        .flatMap { instanciate(OID($0)) }
    }

    internal func createBranch(from commit: Commit, name: String, checkout: Bool, force: Bool = false) -> Result<Reference, Error> {
        var pointer: OpaquePointer?

        return git_try("git_branch_create") {
            git_branch_create(&pointer, self.pointer, name, commit.pointer, force ? 0 : 1)
        }
        .map { Reference(pointer!) }
        .if(checkout,
            then: { self.checkout(reference: $0, strategy: .Safe) })
    }

    func commit(message: String, signature: Signature) -> Result<Commit, Error> {
        return index()
            .flatMap { index in Duo(index, self).commit(message: message, signature: signature) }
    }

    func remoteRepo(named name: String) -> Result<Remote, Error> {
        return remoteLookup(named: name) { $0.map { Remote($0) } }
    }

    func remoteLookup<A>(named name: String, _ callback: (Result<OpaquePointer, Error>) -> A) -> A {
        var pointer: OpaquePointer?

        let result = _result((), pointOfFailure: "git_remote_lookup") {
            git_remote_lookup(&pointer, self.pointer, name)
        }.map { pointer! }

        return callback(result)
    }

    func remote(name: String) -> Result<Remote, Error> {
        var pointer: OpaquePointer?

        return git_try("git_remote_lookup") {
            git_remote_lookup(&pointer, self.pointer, name)
        }.map { Remote(pointer!) }
    }
}

public extension Repository {
    class func exists(at url: URL) -> Bool {
        if case .success(_) = at(url: url) {
            return true
        }
        return false
    }
    
    class func at(url: URL, fixDetachedHead: Bool = true) -> Result<Repository, Error> {
        var pointer: OpaquePointer?

        return git_try("git_repository_open") {
            url.withUnsafeFileSystemRepresentation {
                git_repository_open(&pointer, $0)
            }
        }
        .map { _ in Repository(pointer!) }
        .if(fixDetachedHead,
            then: { repo in repo.detachedHeadFix().map { _ in repo } })
    }

    class func create(at url: URL) -> Result<Repository, Error> {
        var pointer: OpaquePointer?

        return _result({ Repository(pointer!) }, pointOfFailure: "git_repository_init") {
            url.path.withCString { path in
                git_repository_init(&pointer, path, 0)
            }
        }
    }
}

// index
public extension Repository {
    ///Unstage files by relative path
    func resetDefault(paths: [String]) -> R<Void> {
        return HEAD()
            | { $0.targetOID }
            | { self.commit(oid: $0) }
            | { resetDefault(commit: $0, paths: paths) }
    }
    
    func resetDefault(commit: Commit, paths: [String]) -> R<Void> {
        git_try("git_reset_default") {
            paths.with_git_strarray { strarray in
                git_reset_default(self.pointer, commit.pointer, &strarray)
            }
        }
    }
    
    func resetHard(paths: [String] = []) -> R<Void> {
        BranchTarget.HEAD.with(self).commitInstance | { self.resetHard(commit: $0, paths: paths) }
    }
    
    func resetHard(commit: Commit, paths: [String], options: CheckoutOptions = CheckoutOptions()) -> R<Void> {
        git_try("git_reset") {
            options.with_git_checkout_options { options in
                paths.with_git_strarray { strarray in
                    if strarray.count > 0 {
                        options.paths = strarray
                    }
                    
                    return git_reset(self.pointer, commit.pointer, GIT_RESET_HARD, &options)
                }
            }
        }
    }
    
    ///Stage files by relative path
    func add(relPaths: [String]) -> R<()> {
        index().flatMap { $0.add(paths: relPaths) }
    }
    
    func remove(relPaths: [String]) -> R<()> {
         index()
            .flatMap { $0.remove(paths: relPaths) }
    }
}

// Remote
public extension Repository {
    func createRemote(str: String) -> Result<Remote, Error> {
        var pointer: OpaquePointer?

        return _result({ Remote(pointer!) }, pointOfFailure: "git_remote_create") {
            "tempName".withCString { tempName in
                str.withCString { url in
                    git_remote_create(&pointer, self.pointer, tempName, url)
                }
            }
        }
    }
}

// STATIC funcs
public extension Repository {
    static func clone(from remoteURL: URL, to localURL: URL, options: CloneOptions = CloneOptions()) -> Result<Repository, Error> {
        var pointer: OpaquePointer?
        let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString

        return git_try("git_clone") {
            options.with_git_clone_options { clone_options in
                localURL.withUnsafeFileSystemRepresentation { git_clone(&pointer, remoteURLString, $0, &clone_options) }
            }
        }.map { Repository(pointer!) }
    }
}

////////////////////////////////////////////////////////////////////
/// ERRORS
////////////////////////////////////////////////////////////////////

enum RepositoryError: Error {
    case FailedToGetRepoUrl
}

extension RepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FailedToGetRepoUrl:
            return "FailedToGetRepoUrl. Url is nil?"
        }
    }
}

///////////////////////////////////////////
/// STAGE and unstage all files
///////////////////////////////////////////
public extension Repository {
    /// stageAllFiles
    func addAllFiles() -> Result<(),Error> {
        let entries = self.status() | { $0.compactMap { $0.indexToWorkDir }}

        return combine(entries, directoryURL)
            | { entries, url in entries | { $0.getFileAbsPathUsing(repoPath: url.path) } }
            | { paths in self.index()   | { $0.add(paths: paths) } }
    }

    /// unstageAllFiles
    func resetAllFiles() -> Result<(),Error>  {
        let entries = self.status() | { $0.compactMap { $0.indexToWorkDir }}

        return combine(entries, directoryURL)
            | { entries, url in entries | { $0.getFileAbsPathUsing(repoPath: url.path) } }
            | { paths in self.index()   | { _ in self.resetDefault(paths: paths) } }
    }
}

fileprivate extension Diff.Delta {
    func getFileAbsPathUsing(repoPath: String) -> String {
        return "\(repoPath)/" + ( (self.newFile?.path ?? self.oldFile?.path) ?? "" )
    }
}

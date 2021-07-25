//
//  Repository+Status.swift
//  SwiftGit2-OSX
//
//  Created by loki on 21.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public final class StatusIterator {
    public var pointer: OpaquePointer?

    public init(_ pointer: OpaquePointer?) {
        self.pointer = pointer
    }

    deinit {
        if let pointer = pointer {
            git_status_list_free(pointer)
        }
    }
}

extension StatusIterator: RandomAccessCollection {
    public typealias Element = StatusEntry
    public typealias Index = Int
    public typealias SubSequence = StatusIterator
    public typealias Indices = DefaultIndices<StatusIterator>

    public subscript(position: Int) -> StatusEntry {
        _read {
            let s = git_status_byindex(pointer!, position)
            yield StatusEntry(from: s!.pointee)
        }
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int {
        if let pointer = pointer {
            return git_status_list_entrycount(pointer)
        }

        return 0
    }

    public func index(before i: Int) -> Int { return i - 1 }
    public func index(after i: Int) -> Int { return i + 1 }
}

public extension Repository {
    // CheckThatRepoIsEmpty
    var repoIsBare: Bool {
        git_repository_is_bare(pointer) == 1 ? true : false
    }

    func status(options: StatusOptions = StatusOptions()) -> Result<StatusIteratorNew, Error> {
        var pointer: OpaquePointer?

        if repoIsBare {
            let si = StatusIterator(nil)
            
            return .success( StatusIteratorNew(iterator: si, repo: self)  )
        }

        return options.with_git_status_options { options in
            _result({ StatusIterator(pointer!) }, pointOfFailure: "git_status_list_new") {
                git_status_list_new(&pointer, self.pointer, &options)
            }
        }
        .map{ StatusIteratorNew(iterator: $0, repo: self )}
    }
}

//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////
/////////////////////////////////////////

public final class StatusIteratorNew {
    public var repo: Repository
    public var iterator: StatusIterator

    public init( iterator: StatusIterator, repo: Repository ) {
        self.iterator = iterator
        self.repo = repo
    }
}

extension StatusIteratorNew: RandomAccessCollection {
    public typealias Element = UiStatusEntryX
    public typealias Index = Int
    public typealias SubSequence = StatusIteratorNew
    public typealias Indices = DefaultIndices<StatusIteratorNew>
    
    public subscript(position: Int) -> UiStatusEntryX {
        let entry = iterator[position]
        
        var stagedPatch: R<Patch?>
        var unStagedPatch: R<Patch?>
        
        if let hti = entry.headToIndex {
            stagedPatch = repo.patchFrom(delta: hti)
                .map{ patch -> Patch? in patch }
        } else {
            stagedPatch = .success(nil)
        }
        
        if let itw =  entry.indexToWorkDir {
            unStagedPatch = repo.patchFrom(delta: itw)
                .map{ patch -> Patch? in patch }
        } else {
            unStagedPatch = .success(nil)
        }
        
        //let changes = try? getChanged(position: position).flatMap{ $0.asDeltas() }.get()
        //let changesDelta = changes?.first
        
        let changesDelta = try? getChanged(position: position).get()
        
        // Path spec works perfectly!
        // print(iterator[position].relPath)
        // print( (changesDelta?.newFile?.path ?? changesDelta?.oldFile?.path)! )
        
        return StatusEntryNew(iterator[position], stagedPatch: stagedPatch, unStagedPatch: unStagedPatch, changesDeltas: changesDelta)
    }
    
    private func getChanged(position: Int) -> R<[Diff.Delta]?> {
        let relPath = iterator[position].relPath
//
        let repo = self.repo
//
//        return repo.headCommit()
//            .flatMap{ $0.tree() }
//            .flatMap { headTree -> Result<Diff, Error>in
//                let options = DiffOptions(pathspec: [path])
//
//                return repo.diffTreeToWorkdir(tree: headTree, options: options)
//            }
        
        var file = iterator[position].headToIndex?.oldFile
        repo.loadBlobFor(file: &file)
        
        guard let blobHead = file?.blob else { return .success(nil)}
        
        
        return repo.blobCreateFromWorkdirAsBlob(relPath: relPath)
            .flatMap { workdirBlob in
                repo.diffBlobs(old: blobHead, new: workdirBlob)
            }
            .map{ delta -> [Diff.Delta]? in delta }
    }
    
    public var startIndex: Int { 0 }
    public var endIndex: Int { iterator.endIndex }
    
    public func index(before i: Int) -> Int { return i - 1 }
    public func index(after i: Int) -> Int { return i + 1 }
}

private struct StatusEntryNew: UiStatusEntryX {
    private var entry: StatusEntry
    private var stagedPatch_: Result<Patch?, Error>
    private var unStagedPatch_: Result<Patch?, Error>
    
    init(_ entry: StatusEntry, stagedPatch: Result<Patch?, Error>, unStagedPatch: Result<Patch?, Error>, changesDeltas: [Diff.Delta]?) {
        self.entry = entry
        self.stagedPatch_ = stagedPatch
        self.unStagedPatch_ = unStagedPatch
        self.changesDeltas = changesDeltas?.first
    }
    
    public var oldFileRelPath: String? { entry.headToIndex?.oldFile?.path ?? entry.indexToWorkDir?.oldFile?.path }
    
    public var newFileRelPath: String? { entry.headToIndex?.newFile?.path ?? entry.indexToWorkDir?.newFile?.path }
    
    public var stagedPatch: Result<Patch?, Error> { stagedPatch_ }
    
    public var unstagedPatch: Result<Patch?, Error> { unStagedPatch_ }
    
    var stagedDeltas: Diff.Delta? { entry.indexToWorkDir }
    
    var unStagedDeltas: Diff.Delta? { entry.headToIndex }
    
    var changesDeltas: Diff.Delta?
    
    public var stageState: StageState {
        if entry.headToIndex != nil && entry.indexToWorkDir != nil {
            return .mixed
        }
        
        if let _ = entry.headToIndex {
            return .staged
        }
        
        if let _ = entry.indexToWorkDir {
            return .unstaged
        }
        
        assert(false)
        return .mixed
    }
    
    var status: StatusEntry.Status { entry.status }
    
    func statusFull() -> [Diff.Delta.Status] {
        if let status = stagedDeltas?.status,
           unStagedDeltas == nil {
                return [status]
        }
        if let status = unStagedDeltas?.status,
            stagedDeltas == nil {
                return [status]
        }
        
        guard let workDir = stagedDeltas?.status else { return [.unmodified] }
        guard let index = unStagedDeltas?.status else { return [.unmodified] }
        
        if workDir == index {
            return [workDir]
        }
        
        return [workDir, index]
    }
}



/////////////////////////////////
// NEW STATUS ENTRY
/////////////////////////////////

public protocol UiStatusEntryX {
    var stageState: StageState { get }
    var stagedPatch: Result<Patch?, Error> { get }
    var unstagedPatch: Result<Patch?, Error> { get }
    
    var stagedDeltas: Diff.Delta? { get }
    var unStagedDeltas: Diff.Delta? { get }
    var changesDeltas: Diff.Delta? { get }
    
    var oldFileRelPath: String? { get }
    var newFileRelPath: String? { get }
    
    var status: StatusEntry.Status { get }
    
    func statusFull() -> [Diff.Delta.Status]
}

public enum StageState {
    case mixed
    case staged
    case unstaged
}

fileprivate extension StatusEntry{
    var relPath: String {
        self.headToIndex?.newFile?.path     ?? self.indexToWorkDir?.newFile?.path ??
            self.headToIndex?.oldFile?.path ?? self.indexToWorkDir?.oldFile?.path ?? ""
    }
}

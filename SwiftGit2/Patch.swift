//
//  Patch.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Patch {
	let pointer: OpaquePointer
	
	public init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_patch_free(pointer)
	}
	
	public static func fromFiles(old: Diff.File?, new: Diff.File?, options: DiffOptions? = nil) -> Result<Patch, Error> {
		var patchPointer: OpaquePointer? = nil
	
		return _result({ Patch(patchPointer!) }, pointOfFailure: "git_patch_from_blobs") {
			git_patch_from_blobs(&patchPointer, old?.blob?.pointer, old?.path, new?.blob?.pointer, new?.path, options?.pointer)
		}
	}
	
	public static func fromBlobs(old: Blob?, new: Blob?, options: DiffOptions? = nil) -> Result<Patch, Error> {
		var patchPointer: OpaquePointer? = nil
		
		return _result({ Patch(patchPointer!) }, pointOfFailure: "git_patch_from_blobs") {
			git_patch_from_blobs(&patchPointer, old?.pointer, nil, new?.pointer, nil, options?.pointer)
		}
	}
}

public extension Patch {
	func asDelta() -> Diff.Delta {
		return Diff.Delta(git_patch_get_delta(pointer).pointee)
	}
	
	//DOESNT WORKS
	func asHunks() -> Result<[Diff.Hunk],Error> {
		var hunks = [Diff.Hunk]()
		
		for i in 0..<numHunks() {
			switch hunkBy(idx: i) {
			case .success(let hunk):
				hunks.append(hunk)
			case .failure(let error):
				return .failure(error)
			}
		}
		
		return .success(hunks)
	}
	
	func asBuffer() -> Result<Buffer, Error> {
		let buff = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
		buff.pointee = git_buf(ptr: nil, asize: 0, size: 0)
		
		return _result({ Buffer(pointer: buff) }, pointOfFailure: "git_patch_to_buf") {
			git_patch_to_buf(buff, pointer)
		}
	}
	
	func size() -> Int {
		return git_patch_size(pointer, 0, 0, 0)
	}
	
	func numHunks() -> Int {
		return git_patch_num_hunks(pointer)
	}
}

extension Patch {
	func hunkBy(idx: Int) -> Result<Diff.Hunk, Error> { // TODO: initialize lines
		var hunkPointer: UnsafePointer<git_diff_hunk>? = nil
		var linesCount : Int = 0

		let result = git_patch_get_hunk(&hunkPointer, &linesCount, pointer, idx)
		if GIT_OK.rawValue != result {
			return .failure(NSError(gitError: result, pointOfFailure: "git_patch_get_hunk"))
		}
		
		return getLines(count: linesCount, inHunkIdx: idx)
			.map { Diff.Hunk(hunkPointer!.pointee, lines: $0) }
	}
	
	func getLines(count: Int, inHunkIdx: Int) -> Result<[Diff.Line], Error> {
		var lines = [Diff.Line]()
		
		for i in 0..<count {
			var linePointer: UnsafePointer<git_diff_line>? = nil
			
			let result = _result((), pointOfFailure: "git_patch_get_line_in_hunk") {
				git_patch_get_line_in_hunk(&linePointer, pointer, inHunkIdx, i)
			}
			
			switch result {
			case .success(_):
				lines.append(Diff.Line(linePointer!.pointee))
			case .failure(let error):
				return .failure(error)
			}
		}
		
		return .success(lines)
	}
	
	public func getText() -> Result<String, Error> {
		self.asBuffer().flatMap{ $0.asStringRez() }
	}
	
	public func getTextHeader() -> Result<String, Error> {
		getText().map{ $0.stringBefore("@") }
	}
}

////////////////////////////////////////////
// HELPERS
///////////////////////////////////////////
fileprivate extension String {
	func stringBefore(_ delimiter: Character) -> String {
		if let index = firstIndex(of: delimiter) {
			return String(prefix(upTo: index))
		} else {
			return ""
		}
	}
}

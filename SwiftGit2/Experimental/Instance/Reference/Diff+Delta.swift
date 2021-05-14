//
//  Diff+Delta.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

extension Diff {	
	public func asDeltas() -> Result<[Delta],Error> {
		var cb = DiffEachCallbacks()
		
		return _result( { cb.deltas } , pointOfFailure: "git_diff_foreach") {
			git_diff_foreach(self.pointer, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
		}
	}
}

public extension Diff{
	struct Delta {
		public static let type = GIT_OBJECT_REF_DELTA

		public let status: Diff.Delta.Status
		public let statusChar : Character
		public let flags: Flags
		public let oldFile: File?
		public let newFile: File?
		
		///DELETE ME.
		///SOMETIMES THIS HUNKS IS EMPTY
		///USE repo.hunksFrom(delta....)
		public var hunks = [Hunk]()
		
		public init(_ delta: git_diff_delta) {
			self.status = Diff.Delta.Status(rawValue: delta.status.rawValue) ?? .unmodified
			self.statusChar = Character(UnicodeScalar(UInt8(git_diff_status_char(delta.status))))
			self.flags = Flags(rawValue: delta.flags)
			self.oldFile = File(delta.old_file)
			self.newFile = File(delta.new_file)
		}
	}
}

extension Diff.Delta: Identifiable {
	public var id: String {
		var finalId: String = ""
		
		if let newPath = self.newFile?.path { finalId += newPath }
		
		if let oldPath = self.oldFile?.path { finalId += oldPath }
		
		return finalId
	}
}


public extension Diff.Delta {
	enum Status : UInt32 {
		case unmodified		= 0		/**< no changes */
		case added			= 1		/**< entry does not exist in old version */
		case deleted		= 2		/**< entry does not exist in new version */
		case modified		= 3		/**< entry content changed between old and new */
		case renamed		= 4		/**< entry was renamed between old and new */
		case copied			= 5		/**< entry was copied from another old entry */
		case ignored		= 6		/**< entry is ignored item in workdir */
		case untracked		= 7 	/**< entry is untracked item in workdir */
		case typechange		= 8		/**< type of entry changed between old and new */
		case unreadable		= 9		/**< entry is unreadable */
		case conflicted		= 10	/**< entry in the index is conflicted */
	} // git_delta_t
}

public extension Diff {
	struct File {
		public let oid: OID
		public let path: String
		public let size: UInt64
		public let flags: Flags
		public var blob: Blob?

		public init(_ diffFile: git_diff_file) {
			self.oid = OID(diffFile.id)
			let path = diffFile.path
			self.path = path.map(String.init(cString:))!
			self.size = diffFile.size
			self.flags = Flags(rawValue: diffFile.flags)
		}
	}
	
	struct Hunk {
		public let oldStart : Int
		public let oldLines : Int
		public let newStart : Int
		public let newLines : Int
		public let header   : String?
		
		public var lines : [Line]
		
		public init(_ hunk: git_diff_hunk, lines: [Line] = [Line]()) {
			oldStart = Int(hunk.old_start)
			oldLines = Int(hunk.old_lines)
			newStart = Int(hunk.new_start)
			newLines = Int(hunk.new_lines)

			let bytes = Mirror(reflecting: hunk.header)
				.children
				.map { UInt8(bitPattern: $0.value as! Int8) }
				.filter { $0 > 0 }
			
			header = String(bytes: bytes, encoding: .utf8)
			self.lines = lines
		}
	}
	
	struct Line {
		public let origin 		: Int8
		public let old_lineno 	: Int
		public let new_lineno 	: Int
		public let num_lines 	: Int
		public let contentOffset: Int64
		public let content 		: String?

		public init(_ line: git_diff_line) {
			origin 			= line.origin
			old_lineno 		= Int(line.old_lineno)
			new_lineno 		= Int(line.new_lineno)
			num_lines  		= Int(line.num_lines)
			contentOffset   = line.content_offset
			
			var bytes = [UInt8]()
			bytes.reserveCapacity(line.content_len)
			for i in 0..<line.content_len {
				bytes.append(UInt8(bitPattern: line.content[i]))
			}
			
			content = String(bytes: bytes, encoding: .utf8)
		}
	}
}

extension Diff.Hunk : Equatable {
	static public func ==(lhs: Diff.Hunk, rhs: Diff.Hunk) -> Bool {
		return lhs.oldLines == rhs.oldLines &&
			lhs.oldStart == rhs.oldStart &&
			lhs.newStart == rhs.newStart &&
			lhs.newLines == rhs.newLines &&
			lhs.header == rhs.header &&
			lhs.lines.count == rhs.lines.count
	}
}


class DiffEachCallbacks {
	var deltas = [Diff.Delta]()
	
	let each_file_cb : git_diff_file_cb = { delta, progress, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.file(delta: Diff.Delta(delta.unsafelyUnwrapped.pointee), progress: progress)
		
		return 0
	}
	
	let each_line_cb : git_diff_line_cb = { delta, hunk, line, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.line(line: Diff.Line(line.unsafelyUnwrapped.pointee))
		
		return 0
	}
	
	let each_hunk_cb : git_diff_hunk_cb = { delta, hunk, callbacks in
		callbacks.unsafelyUnwrapped
			.bindMemory(to: DiffEachCallbacks.self, capacity: 1)
			.pointee
			.hunk(hunk: Diff.Hunk(hunk.unsafelyUnwrapped.pointee))
		
		return 0
	}
		
	private func file(delta: Diff.Delta, progress: Float32) {
		deltas.append(delta)
	}
	
	private func hunk(hunk: Diff.Hunk) {
		guard let _ = deltas.last 				else { assert(false, "can't add hunk before adding delta"); return }
		
		deltas[deltas.count - 1].hunks.append(hunk)
	}
	
	private func line(line: Diff.Line) {
		guard let _ = deltas.last 				else { assert(false, "can't add line before adding delta"); return }
		guard let _ = deltas.last?.hunks.last 	else { assert(false, "can't add line before adding hunk"); return }
		
		let deltaIdx = deltas.count - 1
		let hunkIdx = deltas[deltaIdx].hunks.count - 1
		
		deltas[deltaIdx].hunks[hunkIdx].lines.append(line)
	}
}

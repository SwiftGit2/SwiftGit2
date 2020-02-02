//
//  Diff+Delta.swift
//  SwiftGit2-OSX
//
//  Created by Loki on 02.02.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

func _result<T>(_ value: T, pointOfFailure: String, block: () -> Int32) -> Result<T, NSError> {
	let result = block()
	if result == GIT_OK.rawValue {
		return .success(value)
	} else {
		return Result.failure(NSError(gitError: result, pointOfFailure: pointOfFailure))
	}
}

extension Diff {	
	public func asDeltas() -> Result<[Delta],NSError> {
		var cb = DiffEachCallbacks()
		
		return _result(cb.deltas, pointOfFailure: "git_diff_foreach") {
			git_diff_foreach(self.pointer, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
		}

	}
}

public extension Diff {
	struct Delta {
		public static let type = GIT_OBJECT_REF_DELTA

		public var status: Diff.Delta.Status
		public var statusChar : Character
		public var flags: Flags
		public var oldFile: File?
		public var newFile: File?
		public var hunks = [Hunk]()
		
		public enum Status : UInt32 {
			case unmodified			= 0
			case added				= 1
			case deleted			= 2
			case modified			= 3
			case renamed			= 4
			case copied				= 5
			case ignored			= 6
			case untracked			= 7
			case typechange			= 8
			case unreadable			= 9
			case conflicted			= 10
		}

		public init(_ delta: git_diff_delta) {
			self.status = Diff.Delta.Status(rawValue: delta.status.rawValue) ?? .unmodified
			self.statusChar = Character(UnicodeScalar(UInt8(git_diff_status_char(delta.status))))
			self.flags = Flags(rawValue: delta.flags)
			self.oldFile = File(delta.old_file)
			self.newFile = File(delta.new_file)
		}
	}

	struct File {
		public var oid: OID
		public var path: String
		public var size: UInt64
		public var flags: Flags

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
		
		public var lines = [Line]()
		
		public init(_ hunk: git_diff_hunk) {
			oldStart = Int(hunk.old_start)
			oldLines = Int(hunk.old_lines)
			newStart = Int(hunk.new_start)
			newLines = Int(hunk.new_lines)

			let bytes = Mirror(reflecting: hunk.header)
				.children
				.map { UInt8(bitPattern: $0.value as! Int8) }
				.filter { $0 > 0 }
			
			header = String(bytes: bytes, encoding: .utf8)
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



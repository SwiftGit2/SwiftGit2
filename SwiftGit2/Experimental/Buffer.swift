//
//  File.swift
//  SwiftGit2-OSX
//
//  Created by Serhii Vynnychenko on 2/10/20.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public final class Buffer {
	let pointer : UnsafeMutablePointer<git_buf>
	
	public init(pointer: UnsafeMutablePointer<git_buf>) {
		self.pointer = pointer
	}
	
	public init?(_ str : String) {
		self.pointer = UnsafeMutablePointer.allocate(capacity: 1)
		self.pointer.pointee = git_buf(ptr: nil, asize: 0, size: 0)
		
		guard let _ = try? set(string: str).get() else { return nil }
	}
	
	deinit {
		dispose()
		pointer.deallocate()
	}
	
	public func dispose() {
		git_buf_dispose(pointer)
	}
}

public extension Buffer {
	var isBinary 	: Bool { 1 == git_buf_is_binary(pointer) }
	var containsNul 	: Bool { 1 == git_buf_contains_nul(pointer) }
	var size			: Int  { pointer.pointee.size }
	var ptr			: UnsafeMutablePointer<Int8> { pointer.pointee.ptr }
	
	func set(string: String) -> Result<(),NSError> {
		guard let data = string.data(using: .utf8) else {
			return .failure(NSError(gitError: 0, pointOfFailure: "string.data(using: .utf8)"))
		}
		return set(data: data)
	}
	
	func set(data: Data) -> Result<(),NSError> {
		let nsData = data as NSData
		
		return _result( { () }, pointOfFailure: "git_buf_set", block: {git_buf_set(pointer, nsData.bytes, nsData.length)})
	}
	
	func asString() -> String? {
		guard !isBinary else { return nil }
		
		let data = Data(bytesNoCopy: pointer.pointee.ptr, count: pointer.pointee.size, deallocator: .none)
		return String(data: data, encoding: .utf8)
	}
	
	func asDiff() -> Result<Diff, NSError> {
		var diff: OpaquePointer? = nil
		return _result( { Diff(diff!) }, pointOfFailure: "git_diff_from_buffer") {
			git_diff_from_buffer(&diff, ptr, size)
		}
	}
}

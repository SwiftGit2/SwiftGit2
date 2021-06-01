//
//  File.swift
//  SwiftGit2-OSX
//
//  Created by Serhii Vynnychenko on 2/10/20.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import Foundation

public final class Buffer {
    var buf: git_buf

    public init(buf: git_buf) {
        self.buf = buf
    }

    public init?(_ str: String) {
        buf = git_buf(ptr: nil, asize: 0, size: 0)

        guard let _ = try? set(string: str).get() else { return nil }
    }

    deinit {
        dispose()
    }

    public func dispose() {
        git_buf_dispose(&buf)
    }
}

public extension Buffer {
    var isBinary: Bool { git_buf_is_binary(&buf) == 1 }
    var containsNul: Bool { git_buf_contains_nul(&buf) == 1 }
    var size: Int { buf.size }
    var ptr: UnsafeMutablePointer<Int8> { buf.ptr }

    func set(string: String) -> Result<Void, Error> {
        guard let data = string.data(using: .utf8) else {
            return .failure(NSError(gitError: 0, pointOfFailure: "string.data(using: .utf8)"))
        }
        return set(data: data)
    }

    func set(data: Data) -> Result<Void, Error> {
        let nsData = data as NSData

        return _result({ () }, pointOfFailure: "git_buf_set") {
            git_buf_set(&buf, nsData.bytes, nsData.length)
        }
    }

    func asString() -> Result<String, Error> {
        guard !isBinary else {
            return .failure(WTF("can't get string from binary buffer"))
        }

        let data = Data(bytesNoCopy: buf.ptr, count: buf.size, deallocator: .none)

        guard let str = String(data: data, encoding: .utf8) else {
            return .failure(WTF("can't read utf8 from buffer"))
        }

        return .success(str)
    }

    func asDiff() -> Result<Diff, Error> {
        var diff: OpaquePointer?
        return _result({ Diff(diff!) }, pointOfFailure: "git_diff_from_buffer") {
            git_diff_from_buffer(&diff, ptr, size)
        }
    }

    // Clean up excess whitespace
    // + make sure there is a trailing newline in the message
    static func prettify(message: String) -> Result<Buffer, Error> {
        var out = git_buf()

        return git_try("git_message_prettify") {
            git_message_prettify(&out, message, 0, /* ascii for # */ 35)
        }.map { Buffer(buf: out) }
    }
}

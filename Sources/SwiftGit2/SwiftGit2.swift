//
//  SwiftGit2.swift
//
//
//  Created by Mathijs Bernson on 01/03/2024.
//

import Foundation
import libgit2

public class SwiftGit2 {
    public static func initialize() -> Result<Int, NSError> {
        let status = git_libgit2_init()
        if status < 0 {
            return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_init"))
        } else {
            return .success(Int(status))
        }
    }

    public static func shutdown() -> Result<Int, NSError> {
        let status = git_libgit2_shutdown()
        if status < 0 {
            return .failure(NSError(gitError: status, pointOfFailure: "git_libgit2_shutdown"))
        } else {
            return .success(Int(status))
        }
    }

    public static var libgit2Version: String {
        var major: Int32 = 0
        var minor: Int32 = 0
        var patch: Int32 = 0
        git_libgit2_version(&major, &minor, &patch)

        let version: String = [major, minor, patch]
            .map(String.init)
            .joined(separator: ".")

        return version
    }

    private static func errorMessage(_ errorCode: Int32) -> String? {
        let last = giterr_last()
        if let lastErrorPointer = last {
            return String(validatingUTF8: lastErrorPointer.pointee.message)
        } else if UInt32(errorCode) == GIT_ERROR_OS.rawValue {
            return String(validatingUTF8: strerror(errno))
        } else {
            return nil
        }
    }
}

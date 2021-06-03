//
//  Libgit2.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/11/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import Clibgit2

public func _result<T>(_ value: T, pointOfFailure: String, block: () -> Int32) -> Result<T, Error> {
    let result = block()
    if result == GIT_OK.rawValue {
        return .success(value)
    }
    else if result > 0 {
        assert(false, "unhandled result > 0")
        return .success(value)
    } else {
        return Result.failure(NSError(gitError: result, pointOfFailure: pointOfFailure))
    }
}

func _result<T>(_ value: () -> T, pointOfFailure: String, block: () -> Int32) -> Result<T, Error> {
    let result = block()
    if result == GIT_OK.rawValue {
        return .success(value())
    }
    else if result > 0 {
        assert(false, "unhandled result > 0")
        return .success(value())
    } else {
        return Result.failure(NSError(gitError: result, pointOfFailure: pointOfFailure))
    }
}

func git_try(_ id: String, block: () -> Int32) -> Result<Void, Error> {
    let result = block()
    if result == GIT_OK.rawValue {
        return .success(())
    }
    else if result > 0 {
        assert(false, "unhandled result > 0")
        return .success(())
    } else {
        return Result.failure(NSError(gitError: result, pointOfFailure: id))
    }
}

func git_instance<T: InstanceProtocol>(of _: T.Type, _ id: String, block: (_ pointer: inout OpaquePointer?) -> Int32) -> Result<T, Error> {
    var pointer: OpaquePointer?
    let result = block(&pointer)
    if result == GIT_OK.rawValue {
        return .success(T(pointer!))
    } else if result > 0 {
        assert(false, "unhandled result > 0")
        return .success(T(pointer!))
    } else {
        return Result.failure(NSError(gitError: result, pointOfFailure: id))
    }
}

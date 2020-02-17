//
//  Libgit2.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/11/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import Clibgit2

extension git_strarray {
	func filter(_ isIncluded: (String) -> Bool) -> [String] {
		return map { $0 }.filter(isIncluded)
	}

	func map<T>(_ transform: (String) -> T) -> [T] {
		return (0..<self.count).map {
			let string = String(validatingUTF8: self.strings[$0]!)!
			return transform(string)
		}
	}
}

func _result<T>(_ value: T, pointOfFailure: String, block: () -> Int32) -> Result<T, NSError> {
	let result = block()
	if result == GIT_OK.rawValue {
		return .success(value)
	} else {
		return Result.failure(NSError(gitError: result, pointOfFailure: pointOfFailure))
	}
}

func _result<T>(_ value: () -> T, pointOfFailure: String, block: () -> Int32) -> Result<T, NSError> {
	let result = block()
	if result == GIT_OK.rawValue {
		return .success(value())
	} else {
		return Result.failure(NSError(gitError: result, pointOfFailure: pointOfFailure))
	}
}

func _resultOf<T>(_ block: () -> Int32, pointOfFailure: String, value: () -> T) -> Result<T, NSError> {
	let result = block()
	if result == GIT_OK.rawValue {
		return .success(value())
	} else {
		return Result.failure(NSError(gitError: result, pointOfFailure: pointOfFailure))
	}
}

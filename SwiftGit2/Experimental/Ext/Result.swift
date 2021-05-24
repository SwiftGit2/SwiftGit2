//
//  Result.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 23.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation

prefix operator ⌘
public prefix func ⌘<T>(right: T) -> Result<T, Error> {
	return .success(right)
}

public extension Result {
	static func |<Transformed>(left: Self, right: (Success)->Transformed) -> Result<Transformed, Failure> { // 2
		return left.map { right($0) }
	}
	
	static func |<Transformed>(left: Self, right: (Success)->Result<Transformed, Failure>) -> Result<Transformed, Failure> { // 2
		return left.flatMap { right($0) }
	}
}

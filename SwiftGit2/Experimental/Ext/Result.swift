//
//  Result.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 23.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation

/////////////////////////////////////////////////////////////////////////////////////////////////////
///Result
/////////////////////////////////////////////////////////////////////////////////////////////////////
internal extension Result {
	func combine<T2>(with other: Result<T2, Error>) -> Result<(Success,T2), Error> {
		switch self {
		case .success(let selfRes):
			switch other {
				case .success(let otherRes):
					return .success( (selfRes, otherRes) )
				case .failure(let error):
					return .failure(error)
			}
		case .failure(let error):
			return .failure(error)
		}
	 }
}

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

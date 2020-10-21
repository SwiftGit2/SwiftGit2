//
//  Array.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.


public extension Array {
	func aggregateResult<Value, Error>() -> Result<[Value], Error> where Element == Result<Value, Error> {
		var values: [Value] = []
		for result in self {
			switch result {
			case .success(let value):
				values.append(value)
			case .failure(let error):
				return .failure(error)
			}
		}
		return .success(values)
	}
}

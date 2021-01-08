//
//  Array.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.


public extension Array {
	// [Result] -> Result<[], Error>
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
	
	// [value].mapResult { $0.methodWithResult() } -> Result<[transformedValue], Error>
	func mapResult<Value, Error>(block: (Element) -> Result<Value, Error>) -> Result<[Value], Error> {
		var values: [Value] = []
		for item in self {
			switch block(item) {
			case .success(let value):
				values.append(value)
			case .failure(let error):
				return .failure(error)
			}
		}
		return .success(values)
	}
}

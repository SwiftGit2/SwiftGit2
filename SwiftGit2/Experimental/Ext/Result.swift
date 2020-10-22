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
	func combine<T2>(with other: Result<T2, Failure>) -> Result<(Success,T2), Failure> {
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

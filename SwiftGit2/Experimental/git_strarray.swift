////
////  StrArray.swift
////  SwiftGit2-OSX
////
////  Created by UKS on 14.10.2020.
////  Copyright © 2020 GitHub, Inc. All rights reserved.
////
//
import Clibgit2

extension Array where Element == String {
	func with_git_strarray<T>(_ body: (inout git_strarray) -> T) -> T {
		return withArrayOfCStrings(self) { strings in
			var arr = git_strarray(strings: &strings, count: self.count)
			return body(&arr)
		}
	}
}

public func withArrayOfCStrings<T>(
	_ args: [String],
	_ body: (inout [UnsafeMutablePointer<CChar>?]) -> T
) -> T {
	var cStrings = args.map { strdup($0) }
	defer {
		cStrings.forEach { free($0) }
	}
	return body(&cStrings)
}

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

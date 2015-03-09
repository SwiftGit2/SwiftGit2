//
//  Libgit2.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/11/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

func == (lhs: git_otype, rhs: git_otype) -> Bool {
	return lhs.value == rhs.value
}

extension git_strarray {
	func filter(f: (String) -> Bool) -> [String] {
		return map { $0 }.filter(f)
	}
	
	func map<T>(f: (String) -> T) -> [T] {
		return Swift.map(0..<self.count) {
			let string = String.fromCString(self.strings[Int($0)])!
			return f(string)
		}
	}
}


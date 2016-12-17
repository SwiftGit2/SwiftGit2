//
//  Libgit2.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/11/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import libgit2

func == (lhs: git_otype, rhs: git_otype) -> Bool {
	return lhs.rawValue == rhs.rawValue
}

extension git_strarray {
	func filter(f: (String) -> Bool) -> [String] {
		return map { $0 }.filter(f)
	}
	
	func map<T>(f: (String) -> T) -> [T] {
		return (0..<self.count).map {
			let string = String(validatingUTF8: self.strings[$0]!)!
			return f(string)
		}
	}
}


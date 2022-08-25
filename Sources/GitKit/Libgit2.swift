//
//  Libgit2.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/11/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Darwin

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

// TODO: Find something better than this.
/// Initializes the Git globals. This function must be called before any other libgit2 function in order to set up global state and threading.
public func initializeGit() {
	git_libgit2_init()
}

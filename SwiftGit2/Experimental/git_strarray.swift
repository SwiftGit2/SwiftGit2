////
////  StrArray.swift
////  SwiftGit2-OSX
////
////  Created by UKS on 14.10.2020.
////  Copyright © 2020 GitHub, Inc. All rights reserved.
////
//
import Clibgit2

func git_strarray(string: String) -> git_strarray {
	var param = UnsafeMutablePointer<Int8>(mutating: (string as NSString).utf8String)
	
	return withUnsafeMutablePointer(to: &param) { pointerToPointer in
		return git_strarray(strings: pointerToPointer, count: 1)
	}
}

// TODO: NOT WORKING
func git_strarray(strings: [String]) -> git_strarray {
	
	var cStrings = strings.map { strdup($0) }
	cStrings.append(nil)
	defer {
		cStrings.forEach { free($0) }
	}

	return cStrings.withUnsafeMutableBufferPointer { cStrings in
		return git_strarray(strings: cStrings.baseAddress, count: strings.count)
	}
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

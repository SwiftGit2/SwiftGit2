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

// TODO: NOT TESTED
func git_strarray(strings: [String]) -> git_strarray {
	//let test = strdup(strings.first!.cString(using: .utf8))
	
	var cStrings = strings.map { strdup(($0 as NSString).utf8String) }
	//cStrings.append(nil)
//	defer {
//		cStrings.forEach { free($0) }
//	}

	return cStrings.withUnsafeMutableBufferPointer { cStrings in
		return git_strarray(strings: cStrings.baseAddress, count: strings.count)
	}
}

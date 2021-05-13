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
			var arr = git_strarray(strings: &strings, count: 1)
			return body(&arr)
		}
	}
}

public func withArrayOfCStrings<T>(
	_ args: [String],
	_ body: (inout [UnsafeMutablePointer<CChar>?]) -> T
) -> T {
	var cStrings = args.map { strdup($0) }
	cStrings.append(nil)
	defer {
		cStrings.forEach { free($0) }
	}
	return body(&cStrings)
}

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
//	defer {
//		cStrings.forEach { free($0) }
//	}
	
	return withUnsafeMutableBytes(of: &cStrings) { bytes -> git_strarray in
		let p = bytes.bindMemory(to: UnsafeMutablePointer<Int8>?.self)
		let strArrayPointer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: strings.count)
		
		strArrayPointer.initialize(from: p.baseAddress!, count: strings.count)
		
		//strArrayPointer.pointee = bytes.b
		
		return git_strarray(strings: strArrayPointer, count: strings.count)
		//bytes.
		
		//strArrayPointer.pointee = bytes.baseAddress
		
		
		//let b = git_strarray(strings: p.baseAddress, count: strings.count)
		//return b
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

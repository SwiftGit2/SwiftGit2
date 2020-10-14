////
////  StrArray.swift
////  SwiftGit2-OSX
////
////  Created by UKS on 14.10.2020.
////  Copyright © 2020 GitHub, Inc. All rights reserved.
////
//
//import Clibgit2
//
//public class StrArray {
//	public let gitStrArr : git_strarray
//	
//	private let needToDispose: Bool
//	
//	public init(_ str: String) {
//		needToDispose = false
//		let strArrayPointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
//		
//		var dirPointer = UnsafeMutablePointer<Int8>(mutating: (str as NSString).utf8String)
//		
//		gitStrArr = git_strarray(strings: &dirPointer, count: 1)
//	}
//	
//	public init (_ strarr: git_strarray) {
//		needToDispose = true
//		gitStrArr = strarr
//	}
//	
////	public init(_ strs: [String]) {
////
////	}
//	
//	deinit {
//		git_strarray_free( &gitStrArr )
//		&gitStrArr.deallocate()
//		
//		if needToDispose {
//			git_strarray_dispose(&gitStrArr)
//		}
//	}
//	
////	func getData() -> [String] {
////
////	}
//	
//	func setData(_ data: [String]) {
//		
//	}
//}

////
////  StrArray.swift
////  SwiftGit2-OSX
////
////  Created by UKS on 14.10.2020.
////  Copyright © 2020 GitHub, Inc. All rights reserved.
////
//
import Clibgit2

public struct StrArray {
	public var strarray : git_strarray
	private var string: String
	private var stringPointer: UnsafeMutablePointer<Int8>?
	
	//private var stringArr: [String]
	
	public init(string: String) {
		self.string = string
		self.stringPointer = UnsafeMutablePointer<Int8>(mutating: (self.string as NSString).utf8String)
		
		self.strarray = git_strarray(strings: &stringPointer, count: 1)
	}
}

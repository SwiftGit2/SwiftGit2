//
//  RemoteRepo.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Remote : InstanceProtocol {
	public let pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_remote_free(pointer)
	}
	
	/// The name of the remote repo
	public var name: String { String(validatingUTF8: git_remote_name(pointer))! }
	
	/// The URL of the remote repo
	///
	/// This may be an SSH URL, which isn't representable using `NSURL`.
	
	//TODO:LAME HACK
	public var URL: String {
		"ssh://" + String(validatingUTF8: git_remote_url(pointer))!
		.replacingOccurrences(of: ":", with: "/")
		
	}
}

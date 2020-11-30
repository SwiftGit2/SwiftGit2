//
//  Instance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public protocol InstanceProtocol {
	var pointer: OpaquePointer { get }
	
	init(_ pointer: OpaquePointer)
}

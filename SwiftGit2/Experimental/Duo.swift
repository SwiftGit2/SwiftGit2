//
//  Duos.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation

public struct Duo<T1,T2> {
	public let value: (T1, T2)
	public init(_ value: (T1, T2)) {
		self.value = value
	}
}

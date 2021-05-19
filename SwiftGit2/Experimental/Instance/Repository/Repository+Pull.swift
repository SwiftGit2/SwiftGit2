//
//  Repository+Pull.swift
//  SwiftGit2-OSX
//
//  Created by loki on 15.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Repository {
	func currentRemote() -> Result<Remote,Error> {
		return self.HEAD()
			.flatMap{ $0.asBranch() }
			.flatMap{ Duo($0, self).remote() }
	}
	
	func mergeAnalysis() -> Result<MergeAnalysis, Error> {
		return self.HEAD()
			.flatMap { $0.asBranch() }
			.flatMap { $0.upstream() }
			.flatMap { $0.commitOID }
			.flatMap { self.annotatedCommit(oid: $0) }
			.flatMap { self.mergeAnalysis(their_head: $0) }
	}
	
	func pull(auth: Auth) {
		// 1. fetch remote
		// 2.
		currentRemote()
			.flatMap { $0.fetch(options: FetchOptions(auth: auth)) }
	}
}

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

extension Repository {
	func currentRemote() -> Result<Remote,Error> {
		return self.HEAD()
			.flatMap{ $0.asBranch() }
			.flatMap{ Duo($0, self).remote() }
	}

	
	func pull() {
		
	}
}

//
//  RepositoryDiff.swift
//  SwiftGit2
//
//  Created by Loki on 5/1/19.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension Repository {
	func diffIndexToWorkDir() -> Result<Diff,NSError> {
		var diff: OpaquePointer? = nil
		let result = git_diff_index_to_workdir(&diff, self.pointer, nil, nil)
		
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_index_to_workdir"))
		}
		
		return .success(Diff(diff!))
	}
}

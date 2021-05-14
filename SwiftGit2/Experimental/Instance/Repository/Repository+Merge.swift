//
//  Repository+Merge.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public extension Repository {
	func merge(our: Commit, their: Commit ) -> Result<Index, Error> {
		var options = MergeOptions()
		var indexPointer : OpaquePointer? = nil
		
		return _result( { Index(indexPointer!) } , pointOfFailure: "git_merge_commits") {
			git_merge_commits(&indexPointer, self.pointer , our.pointer, their.pointer, &options.merge_options)
		}
	}
	
	func mergeAndCommit(our: Commit, their: Commit, signature: Signature) -> Result<Commit, Error> {
		return merge(our: our, their: their)
			.flatMap { index in
				Duo(index,self)
					.commit(message: "TAO_MERGE", signature: signature )
			}
	}
}

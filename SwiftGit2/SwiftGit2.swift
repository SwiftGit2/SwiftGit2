//
//  SwiftGit2.swift
//  SwiftGit2
//
//  Created by Andrew Breckenridge on 10/23/17.
//  MIT.
//

import Clibgit2

private var gitInitialized: Int = ({
	return Int(git_libgit2_init())
})()

func ensureGitInitialized() {
	precondition(gitInitialized >= 0)
}

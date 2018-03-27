//
//  SwiftGit2.swift
//  SwiftGit2
//
//  Created by Andrew Breckenridge on 10/23/17.
//  MIT.
//

#if SWIFT_PACKAGE
	import Clibgit
#else
	import libgit2
#endif

// swiftlint:disable:next identifier_name
let SwiftGit2Init: () = {
    git_libgit2_init()
}()

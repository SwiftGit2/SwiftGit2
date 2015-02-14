//
//  Libgit2.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/11/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

func == (lhs: git_otype, rhs: git_otype) -> Bool {
	return lhs.value == rhs.value
}




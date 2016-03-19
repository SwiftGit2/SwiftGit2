//
//  SwiftGit2.m
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "SwiftGit2.h"
#import "git2.h"

__attribute__((constructor))
static void SwiftGit2Init(void) {
	git_libgit2_init();
}

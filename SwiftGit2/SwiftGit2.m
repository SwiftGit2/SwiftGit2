//
//  SwiftGit2.m
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "SwiftGit2.h"

#include <sys/dirent.h>

__attribute__((constructor))
static void SwiftGit2Init(void) {
	git_libgit2_init();
}

// Declarations in iOS 8.3 /usr/include/dirent.h
/*
DIR *opendir(const char *) __DARWIN_ALIAS_I(opendir);
struct dirent *readdir(DIR *) __DARWIN_INODE64(readdir);
*/

//http://stackoverflow.com/questions/29390112/libcrypto-a-symbols-not-found-for-architecture-i386#answer-29439324

DIR * opendir$INODE64( char * dirName )
{
	return opendir( dirName );
}

struct dirent * readdir$INODE64( DIR * dir )
{
	return readdir( dir );
}

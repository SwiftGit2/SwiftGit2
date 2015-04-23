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

static void SG2CheckoutProgressCallback(const char *path, size_t completed_steps, size_t total_steps, void *payload) {
	if (payload == NULL) return;
	
	SG2CheckoutProgressBlock block = (__bridge SG2CheckoutProgressBlock)payload;
	block((path == nil ? nil : @(path)), completed_steps, total_steps);
}

git_checkout_options SG2CheckoutOptions(SG2CheckoutProgressBlock progress) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-field-initializers"
	git_checkout_options result = GIT_CHECKOUT_OPTIONS_INIT;
#pragma clang diagnostic pop
	
	if (progress != nil) {
		result.progress_cb = SG2CheckoutProgressCallback;
		result.progress_payload = (__bridge void *)[progress copy];
	}
	
	return result;
}

// Declarations in iOS 8.3 /usr/include/dirent.h
/*
DIR *opendir(const char *) __DARWIN_ALIAS_I(opendir);
struct dirent *readdir(DIR *) __DARWIN_INODE64(readdir);
*/

//http://stackoverflow.com/questions/29390112/libcrypto-a-symbols-not-found-for-architecture-i386#answer-29439324

#if TARGET_OS_IPHONE

DIR * opendir$INODE64( char * dirName )
{
	return opendir( dirName );
}

struct dirent * readdir$INODE64( DIR * dir )
{
	return readdir( dir );
}

#endif

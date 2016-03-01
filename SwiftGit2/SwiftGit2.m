//
//  SwiftGit2.m
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "SwiftGit2.h"


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
		result.progress_payload = (__bridge_retained void *)[progress copy];
	}
	
	return result;
}

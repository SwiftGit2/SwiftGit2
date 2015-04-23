//
//  SwiftGit2.h
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

@import Foundation;

//! Project version number for SwiftGit2.
FOUNDATION_EXPORT double SwiftGit2VersionNumber;

//! Project version string for SwiftGit2.
FOUNDATION_EXPORT const unsigned char SwiftGit2VersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SwiftGit2/PublicHeader.h>

#import "git2.h"

typedef void (^SG2CheckoutProgressBlock)(NSString * __nullable, NSUInteger, NSUInteger);

/// A C function for working with Libgit2. This shouldn't be called directly. It's an
/// implementation detail that, unfortunately, leaks through to the public headers.
extern git_checkout_options SG2CheckoutOptions(SG2CheckoutProgressBlock __nullable progress);

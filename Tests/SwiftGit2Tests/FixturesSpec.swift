//
//  FixturesSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Quick
import SwiftGit2

class FixturesSpec: QuickSpec {
	override class func spec() {
		beforeSuite {
            _ = SwiftGit2Init()
			Fixtures.sharedInstance.setUp()
		}

		afterSuite {
			Fixtures.sharedInstance.tearDown()
            _ = SwiftGit2Shutdown()
		}
	}
}

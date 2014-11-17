//
//  RepositorySpec.swift
//  RepositorySpec
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import LlamaKit
import SwiftGit2
import Nimble
import Quick

class RepositorySpec: QuickSpec {
	override func spec() {
		describe("+atURL()") {
			it("should work if the repo exists") {
				let repo = Fixtures.simpleRepository
				expect(repo.directoryURL).notTo(beNil())
			}
			
			it("should fail if the repo doesn't exist") {
				let url = NSURL(fileURLWithPath: "blah")!
				let result = Repository.atURL(url)
				expect(result.error()).notTo(beNil())
			}
		}
	}
}

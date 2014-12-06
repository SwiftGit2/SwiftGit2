//
//  ObjectSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import LlamaKit
import SwiftGit2
import Nimble
import Quick

class CommitSpec: QuickSpec {
	override func spec() {
		describe("init(pointer:)") {
			it("should set its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let commit = repo.commitWithOID(oid).value()
				expect(commit?.oid).to(equal(oid))
				expect(commit?.message).to(equal("Create a README\n"))
			}
		}
	}
}

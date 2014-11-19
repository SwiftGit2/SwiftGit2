//
//  OIDSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/17/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import LlamaKit
import SwiftGit2
import Nimble
import Quick

class OIDSpec: QuickSpec {
	override func spec() {
		describe("init(string:)") {
			it("should be nil if string is too short") {
				expect(OID(string: "123456789012345678901234567890123456789")).to(beNil())
			}

			it("should be nil if string is too long") {
				expect(OID(string: "12345678901234567890123456789012345678901")).to(beNil())
			}

			it("should not be nil if string is just right") {
				expect(OID(string: "1234567890123456789012345678901234567890")).notTo(beNil())
			}
			
			it("should be nil with non-hex characters") {
				expect(OID(string: "123456789012345678901234567890123456789j")).to(beNil())
			}
		}
		
		describe("description") {
			it("should return the SHA") {
				let SHA = "1234567890123456789012345678901234567890"
				let oid = OID(string: SHA)!
				expect(oid.description).to(equal(SHA))
			}
		}
	}
}

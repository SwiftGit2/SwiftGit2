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

func from_git_object<T>(repository: Repository, oid: OID, f: COpaquePointer -> T) -> T{
	let repository = repository.pointer
	var oid = oid.oid
	
	let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
	git_object_lookup(pointer, repository, &oid, GIT_OBJ_ANY)
	let result = f(pointer.memory)
	git_object_free(pointer.memory)
	pointer.dealloc(1)
	
	return result
}

class SignatureSpec: QuickSpec {
	override func spec() {
		describe("init(signature:)") {
			it("should initialize its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let raw_signature = from_git_object(repo, oid) { git_commit_author($0).memory }
				let signature = Signature(signature: raw_signature)
				
				expect(signature.name).to(equal("Matt Diephouse"))
				expect(signature.email).to(equal("matt@diephouse.com"))
				expect(signature.time).to(equal(NSDate(timeIntervalSince1970: 1416186947)))
				expect(signature.timeZone.abbreviation).to(equal("GMT-5"))
			}
		}
	}
}

class CommitSpec: QuickSpec {
	override func spec() {
		describe("init(pointer:)") {
			it("should initialize its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let commit = from_git_object(repo, oid) { Commit(pointer: $0) }
				expect(commit.oid).to(equal(oid))
				expect(commit.message).to(equal("Create a README\n"))
			}
		}
	}
}

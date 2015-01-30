//
//  ReferencesSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/2/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import LlamaKit
import SwiftGit2
import Nimble
import Quick

func from_git_reference<T>(repository: Repository, name: String, f: COpaquePointer -> T) -> T {
	let repository = repository.pointer
	
	let pointer = UnsafeMutablePointer<COpaquePointer>.alloc(1)
	git_reference_lookup(pointer, repository, name.cStringUsingEncoding(NSUTF8StringEncoding)!)
	let result = f(pointer.memory)
	git_object_free(pointer.memory)
	pointer.dealloc(1)
	
	return result
}

class ReferenceSpec: QuickSpec {
	override func spec() {
		describe("init()") {
			it("should initialize its properties") {
				let repo = Fixtures.simpleRepository
				let ref = from_git_reference(repo, "refs/heads/master") { Reference($0) }
				expect(ref.longName).to(equal("refs/heads/master"))
				expect(ref.shortName).to(equal("master"))
				expect(ref.oid).to(equal(OID(string: "c4ed03a6b7d7ce837d31d83757febbe84dd465fd")!))
			}
		}
		
		describe("==") {
			it("should be true with equal references") {
				let repo = Fixtures.simpleRepository
				let ref1 = from_git_reference(repo, "refs/heads/master") { Reference($0) }
				let ref2 = from_git_reference(repo, "refs/heads/master") { Reference($0) }
				expect(ref1).to(equal(ref2))
			}
			
			it("should be false with unequal references") {
				let repo = Fixtures.simpleRepository
				let ref1 = from_git_reference(repo, "refs/heads/master") { Reference($0) }
				let ref2 = from_git_reference(repo, "refs/heads/another-branch") { Reference($0) }
				expect(ref1).notTo(equal(ref2))
			}
		}

		describe("hashValue") {
			it("should be equal with equal references") {
				let repo = Fixtures.simpleRepository
				let ref1 = from_git_reference(repo, "refs/heads/master") { Reference($0) }
				let ref2 = from_git_reference(repo, "refs/heads/master") { Reference($0) }
				expect(ref1.hashValue).to(equal(ref2.hashValue))
			}
		}
	}
}

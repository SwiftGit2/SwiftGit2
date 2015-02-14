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
	git_reference_lookup(pointer, repository, name)
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

class BranchSpec: QuickSpec {
	override func spec() {
		describe("init()") {
			it("should initialize its properties") {
				let repo = Fixtures.mantleRepository
				let branch = from_git_reference(repo, "refs/heads/master") { Branch($0)! }
				expect(branch.longName).to(equal("refs/heads/master"))
				expect(branch.name).to(equal("master"))
				expect(branch.shortName).to(equal(branch.name))
				expect(branch.commit.oid).to(equal(OID(string: "f797bd4837b61d37847a4833024aab268599a681")!))
				expect(branch.oid).to(equal(branch.commit.oid))
			}
		}
		
		describe("==") {
			it("should be true with equal branches") {
				let repo = Fixtures.simpleRepository
				let branch1 = from_git_reference(repo, "refs/heads/master") { Branch($0)! }
				let branch2 = from_git_reference(repo, "refs/heads/master") { Branch($0)! }
				expect(branch1).to(equal(branch2))
			}
			
			it("should be false with unequal branches") {
				let repo = Fixtures.simpleRepository
				let branch1 = from_git_reference(repo, "refs/heads/master") { Branch($0)! }
				let branch2 = from_git_reference(repo, "refs/heads/another-branch") { Branch($0)! }
				expect(branch1).notTo(equal(branch2))
			}
		}

		describe("hashValue") {
			it("should be equal with equal references") {
				let repo = Fixtures.simpleRepository
				let branch1 = from_git_reference(repo, "refs/heads/master") { Branch($0)! }
				let branch2 = from_git_reference(repo, "refs/heads/master") { Branch($0)! }
				expect(branch1.hashValue).to(equal(branch2.hashValue))
			}
		}
	}
}

class TagReferenceSpec: QuickSpec {
	override func spec() {
		describe("init()") {
			it("should work with an annotated tag") {
				let repo = Fixtures.simpleRepository
				let tag = from_git_reference(repo, "refs/tags/tag-2") { TagReference($0)! }
				expect(tag.longName).to(equal("refs/tags/tag-2"))
				expect(tag.name).to(equal("tag-2"))
				expect(tag.shortName).to(equal(tag.name))
				expect(tag.oid).to(equal(OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940")!))
			}
			
			it("should work with a lightweight tag") {
				let repo = Fixtures.mantleRepository
				let tag = from_git_reference(repo, "refs/tags/1.5.4") { TagReference($0)! }
				expect(tag.longName).to(equal("refs/tags/1.5.4"))
				expect(tag.name).to(equal("1.5.4"))
				expect(tag.shortName).to(equal(tag.name))
				expect(tag.oid).to(equal(OID(string: "d9dc95002cfbf3929d2b70d2c8a77e6bf5b1b88a")!))
			}
			
			it("should return nil if not a tag") {
				let repo = Fixtures.simpleRepository
				let tag = from_git_reference(repo, "refs/heads/master") { TagReference($0) }
				expect(tag).to(beNil())
			}
		}
		
		describe("==") {
			it("should be true with equal tag references") {
				let repo = Fixtures.simpleRepository
				let tag1 = from_git_reference(repo, "refs/tags/tag-2") { TagReference($0)! }
				let tag2 = from_git_reference(repo, "refs/tags/tag-2") { TagReference($0)! }
				expect(tag1).to(equal(tag2))
			}
			
			it("should be false with unequal tag references") {
				let repo = Fixtures.simpleRepository
				let tag1 = from_git_reference(repo, "refs/tags/tag-1") { TagReference($0)! }
				let tag2 = from_git_reference(repo, "refs/tags/tag-2") { TagReference($0)! }
				expect(tag1).notTo(equal(tag2))
			}
		}

		describe("hashValue") {
			it("should be equal with equal references") {
				let repo = Fixtures.simpleRepository
				let tag1 = from_git_reference(repo, "refs/tags/tag-2") { TagReference($0)! }
				let tag2 = from_git_reference(repo, "refs/tags/tag-2") { TagReference($0)! }
				expect(tag1.hashValue).to(equal(tag2.hashValue))
			}
		}
	}
}

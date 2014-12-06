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
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let author1 = from_git_object(repo, oid) { commit in
					Signature(signature: git_commit_author(commit).memory)
				}
				let author2 = author1
				
				expect(author1).to(equal(author2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				let oid2 = OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940")!
				
				let author1 = from_git_object(repo, oid1) { commit in
					Signature(signature: git_commit_author(commit).memory)
				}
				let author2 = from_git_object(repo, oid2) { commit in
					Signature(signature: git_commit_author(commit).memory)
				}
				
				expect(author1).notTo(equal(author2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let author1 = from_git_object(repo, oid) { commit in
					Signature(signature: git_commit_author(commit).memory)
				}
				let author2 = author1
				
				expect(author1.hashValue).to(equal(author2.hashValue))
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

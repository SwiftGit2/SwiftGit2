//
//  RemotesSpec.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 1/2/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

import LlamaKit
import SwiftGit2
import Nimble
import Quick

func with_git_remote<T>(repository: Repository, name: String, f: COpaquePointer -> T) -> T {
	let repository = repository.pointer
	
	var pointer: COpaquePointer = nil
	git_remote_lookup(&pointer, repository, name)
	let result = f(pointer)
	git_object_free(pointer)
	
	return result
}

class RemoteSpec: QuickSpec {
	override func spec() {
		describe("init(pointer:)") {
			it("should initialize its properties") {
				let repo = Fixtures.mantleRepository
				let remote = with_git_remote(repo, "upstream") { Remote($0) }
				
				expect(remote.name).to(equal("upstream"))
				expect(remote.URL).to(equal("git@github.com:Mantle/Mantle.git"))
			}
		}
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.mantleRepository
				let remote1 = with_git_remote(repo, "upstream") { Remote($0) }
				let remote2 = remote1
				expect(remote1).to(equal(remote2))
			}
			
			it("should be false with unequal objcets") {
				let repo = Fixtures.mantleRepository
				let origin = with_git_remote(repo, "origin") { Remote($0) }
				let upstream = with_git_remote(repo, "upstream") { Remote($0) }
				expect(origin).notTo(equal(upstream))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objcets") {
				let repo = Fixtures.mantleRepository
				let remote1 = with_git_remote(repo, "upstream") { Remote($0) }
				let remote2 = remote1
				expect(remote1.hashValue).to(equal(remote2.hashValue))
			}
		}
	}
}

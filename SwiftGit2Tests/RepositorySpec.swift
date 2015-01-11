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
		
		describe("-blobWithOID()") {
			it("should return the commit if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let result = repo.blobWithOID(oid)
				let blob = result.value()
				expect(blob).notTo(beNil())
				expect(blob?.oid).to(equal(oid))
			}
			
			it("should error if the blob doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.blobWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
			
			it("should error if the oid doesn't point to a blob") {
				let repo = Fixtures.simpleRepository
				// This is a tree in the repository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.blobWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
		}
		
		describe("-commitWithOID()") {
			it("should return the commit if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.commitWithOID(oid)
				let commit = result.value()
				expect(commit).notTo(beNil())
				expect(commit?.oid).to(equal(oid))
			}
			
			it("should error if the commit doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.commitWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
			
			it("should error if the oid doesn't point to a commit") {
				let repo = Fixtures.simpleRepository
				// This is a tree in the repository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.commitWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
		}
		
		describe("-tagWithOID()") {
			it("should return the tag if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let result = repo.tagWithOID(oid)
				let tag = result.value()
				expect(tag).notTo(beNil())
				expect(tag?.oid).to(equal(oid))
			}
			
			it("should error if the tag doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.tagWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
			
			it("should error if the oid doesn't point to a tag") {
				let repo = Fixtures.simpleRepository
				// This is a commit in the repository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.tagWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
		}
		
		describe("-treeWithOID()") {
			it("should return the tree if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.treeWithOID(oid)
				let tree = result.value()
				expect(tree).notTo(beNil())
				expect(tree?.oid).to(equal(oid))
			}
			
			it("should error if the tree doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.treeWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
			
			it("should error if the oid doesn't point to a tree") {
				let repo = Fixtures.simpleRepository
				// This is a commit in the repository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.treeWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
		}
		
		describe("-objectWithOID()") {
			it("should work with a blob") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				let blob   = repo.blobWithOID(oid).value()
				let result = repo.objectWithOID(oid)
				expect(result.value()).notTo(beNil())
				expect(result.value() as Blob?).to(equal(blob))
			}
			
			it("should work with a commit") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				let commit = repo.commitWithOID(oid).value()
				let result = repo.objectWithOID(oid)
				expect(result.value()).notTo(beNil())
				expect(result.value() as Commit?).to(equal(commit))
			}
			
			it("should work with a tag") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				let tag    = repo.tagWithOID(oid).value()
				let result = repo.objectWithOID(oid)
				expect(result.value()).notTo(beNil())
				expect(result.value() as Tag?).to(equal(tag))
			}
			
			it("should work with a tree") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				let tree   = repo.treeWithOID(oid).value()
				let result = repo.objectWithOID(oid)
				expect(result.value()).notTo(beNil())
				expect(result.value() as Tree?).to(equal(tree))
			}
			
			it("should error if there's no object with that oid") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				let result = repo.objectWithOID(oid)
				expect(result.error()).notTo(beNil())
			}
		}
		
		describe("-objectFromPointer(PointerTo)") {
			it("should work with commits") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let pointer = PointerTo<Commit>(oid)
				let commit = repo.commitWithOID(oid).value()!
				expect(repo.objectFromPointer(pointer).value()).to(equal(commit))
			}
			
			it("should work with trees") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let pointer = PointerTo<Tree>(oid)
				let tree = repo.treeWithOID(oid).value()!
				expect(repo.objectFromPointer(pointer).value()).to(equal(tree))
			}
			
			it("should work with blobs") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let pointer = PointerTo<Blob>(oid)
				let blob = repo.blobWithOID(oid).value()!
				expect(repo.objectFromPointer(pointer).value()).to(equal(blob))
			}
			
			it("should work with tags") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let pointer = PointerTo<Tag>(oid)
				let tag = repo.tagWithOID(oid).value()!
				expect(repo.objectFromPointer(pointer).value()).to(equal(tag))
			}
		}
		
		describe("-objectFromPointer(Pointer)") {
			it("should work with commits") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let pointer = Pointer.Commit(oid)
				let commit = repo.commitWithOID(oid).value()!
				let result = repo.objectFromPointer(pointer).map { $0 as Commit }.value()
				expect(result).to(equal(commit))
			}
			
			it("should work with trees") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let pointer = Pointer.Tree(oid)
				let tree = repo.treeWithOID(oid).value()!
				let result = repo.objectFromPointer(pointer).map { $0 as Tree }.value()
				expect(result).to(equal(tree))
			}
			
			it("should work with blobs") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let pointer = Pointer.Blob(oid)
				let blob = repo.blobWithOID(oid).value()!
				let result = repo.objectFromPointer(pointer).map { $0 as Blob }.value()
				expect(result).to(equal(blob))
			}
			
			it("should work with tags") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let pointer = Pointer.Tag(oid)
				let tag = repo.tagWithOID(oid).value()!
				let result = repo.objectFromPointer(pointer).map { $0 as Tag }.value()
				expect(result).to(equal(tag))
			}
		}
		
		describe("-allRemotes()") {
			it("should return an empty list if there are no remotes") {
				let repo = Fixtures.simpleRepository
				let result = repo.allRemotes()
				expect(result.value()).to(equal([]))
			}
			
			it("should return all the remotes") {
				let repo = Fixtures.mantleRepository
                let remotes = repo.allRemotes().value()
                let names = remotes?.map { $0.name }
                expect(remotes?.count).to(equal(2))
                expect(names).to(contain("origin", "upstream"))
			}
		}
		
		describe("-remoteWithName()") {
			it("should return the remote if it exists") {
				let repo = Fixtures.mantleRepository
                let result = repo.remoteWithName("upstream")
                expect(result.value()?.name).to(equal("upstream"))
			}
			
			it("should error if the remote doesn't exist") {
				let repo = Fixtures.simpleRepository
                let result = repo.remoteWithName("nonexistent")
                expect(result.error()).notTo(beNil())
			}
		}
	}
}

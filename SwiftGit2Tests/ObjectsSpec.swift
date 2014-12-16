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
				let signature = Signature(raw_signature)
				
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
					Signature(git_commit_author(commit).memory)
				}
				let author2 = author1
				
				expect(author1).to(equal(author2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				let oid2 = OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940")!
				
				let author1 = from_git_object(repo, oid1) { commit in
					Signature(git_commit_author(commit).memory)
				}
				let author2 = from_git_object(repo, oid2) { commit in
					Signature(git_commit_author(commit).memory)
				}
				
				expect(author1).notTo(equal(author2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let author1 = from_git_object(repo, oid) { commit in
					Signature(git_commit_author(commit).memory)
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
				let oid = OID(string: "24e1e40ee77525d9e279f079f9906ad6d98c8940")!
				
				let commit = from_git_object(repo, oid) { Commit($0) }
				let author = from_git_object(repo, oid) { commit in
					Signature(git_commit_author(commit).memory)
				}
				let committer = from_git_object(repo, oid) { commit in
					Signature(git_commit_committer(commit).memory)
				}
				let tree = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				let parents = [
					OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!,
				]
				expect(commit.oid).to(equal(oid))
				expect(commit.tree).to(equal(tree))
				expect(commit.parents).to(equal(parents))
				expect(commit.message).to(equal("List branches in README\n"))
				expect(commit.author).to(equal(author))
				expect(commit.committer).to(equal(committer))
			}
			
			it("should handle 0 parents") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let commit = from_git_object(repo, oid) { Commit($0) }
				expect(commit.parents).to(equal([]))
			}
			
			it("should handle multiple parents") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "c4ed03a6b7d7ce837d31d83757febbe84dd465fd")!
				
				let commit = from_git_object(repo, oid) { Commit($0) }
				let parents = [
					OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e")!,
					OID(string: "57f6197561d1f99b03c160f4026a07f06b43cf20")!,
				]
				expect(commit.parents).to(equal(parents))
			}
		}
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let commit1 = from_git_object(repo, oid) { Commit($0) }
				let commit2 = commit1
				expect(commit1).to(equal(commit2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				let oid2 = OID(string: "c4ed03a6b7d7ce837d31d83757febbe84dd465fd")!
				
				let commit1 = from_git_object(repo, oid1) { Commit($0) }
				let commit2 = from_git_object(repo, oid2) { Commit($0) }
				expect(commit1).notTo(equal(commit2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let commit1 = from_git_object(repo, oid) { Commit($0) }
				let commit2 = commit1
				expect(commit1.hashValue).to(equal(commit2.hashValue))
			}
		}
	}
}

class TreeEntrySpec: QuickSpec {
	override func spec() {
		describe("init(attributes:object:name:)") {
			it("should set its properties") {
				let attributes = Int32(GIT_FILEMODE_BLOB.value)
				let object = Object.Blob(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!)
				let name = "README.md"
				
                let entry = Tree.Entry(attributes: attributes, object: object, name: name)
				expect(entry.attributes).to(equal(attributes))
				expect(entry.object).to(equal(object))
				expect(entry.name).to(equal(name))
			}
		}
		
		describe("init(pointer:") {
			it("should set its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				
				let entry = from_git_object(repo, oid) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
				expect(entry.attributes).to(equal(Int32(GIT_FILEMODE_BLOB.value)))
				expect(entry.object).to(equal(Object.Blob(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!)))
				expect(entry.name).to(equal("README.md"))
			}
		}
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				
				let entry1 = from_git_object(repo, oid) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
				let entry2 = entry1
				expect(entry1).to(equal(entry2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				let oid2 = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let entry1 = from_git_object(repo, oid1) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
				let entry2 = from_git_object(repo, oid2) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
				expect(entry1).notTo(equal(entry2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				
				let entry1 = from_git_object(repo, oid) { Tree.Entry(git_tree_entry_byindex($0, 0)) }
				let entry2 = entry1
				expect(entry1.hashValue).to(equal(entry2.hashValue))
			}
		}
	}
}

class TreeSpec: QuickSpec {
	override func spec() {
		describe("init(pointer:)") {
			it("should initialize its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				
				let tree = from_git_object(repo, oid) { Tree($0) }
				let entries = [
					"README.md": Tree.Entry(attributes: Int32(GIT_FILEMODE_BLOB.value), object: .Blob(OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!), name: "README.md"),
				]
				expect(tree.entries).to(equal(entries))
			}
		}
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				
				let tree1 = from_git_object(repo, oid) { Tree($0) }
				let tree2 = tree1
				expect(tree1).to(equal(tree2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				let oid2 = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let tree1 = from_git_object(repo, oid1) { Tree($0) }
				let tree2 = from_git_object(repo, oid2) { Tree($0) }
				expect(tree1).notTo(equal(tree2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "219e9f39c2fb59ed1dfb3e78ed75055a57528f31")!
				
				let tree1 = from_git_object(repo, oid) { Tree($0) }
				let tree2 = tree1
				expect(tree1.hashValue).to(equal(tree2.hashValue))
			}
		}
	}
}

class BlobSpec: QuickSpec {
	override func spec() {
		describe("init(pointer:)") {
			it("should initialize its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let blob = from_git_object(repo, oid) { Blob($0) }
				let contents = "# Simple Repository\nA simple repository used for testing SwiftGit2.\n\n## Branches\n\n- master\n\n"
				let data = (contents as NSString).dataUsingEncoding(NSUTF8StringEncoding)!
				expect(blob.oid).to(equal(oid))
				expect(blob.data).to(equal(data))
			}
		}
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let blob1 = from_git_object(repo, oid) { Blob($0) }
				let blob2 = blob1
				expect(blob1).to(equal(blob2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				let oid2 = OID(string: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391")!
				
				let blob1 = from_git_object(repo, oid1) { Blob($0) }
				let blob2 = from_git_object(repo, oid2) { Blob($0) }
				expect(blob1).notTo(equal(blob2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let blob1 = from_git_object(repo, oid) { Blob($0) }
				let blob2 = blob1
				expect(blob1.hashValue).to(equal(blob2.hashValue))
			}
		}
	}
}

class TagSpec: QuickSpec {
	override func spec() {
		describe("init(pointer:)") {
			it("should set its properties") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let tag = from_git_object(repo, oid) { Tag($0) }
				let tagger = from_git_object(repo, oid) { Signature(git_tag_tagger($0).memory) }
				
				expect(tag.oid).to(equal(oid))
				expect(tag.target).to(equal(Object.Commit(OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!)))
				expect(tag.name).to(equal("tag-1"))
				expect(tag.tagger).to(equal(tagger))
				expect(tag.message).to(equal("tag-1\n"))
			}
		}
		
		describe("==") {
			it("should be true with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let tag1 = from_git_object(repo, oid) { Tag($0) }
				let tag2 = tag1
				expect(tag1).to(equal(tag2))
			}
			
			it("should be false with unequal objects") {
				let repo = Fixtures.simpleRepository
				let oid1 = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				let oid2 = OID(string: "13bda91157f255ab224ff88d0a11a82041c9d0c1")!
				
				let tag1 = from_git_object(repo, oid1) { Tag($0) }
				let tag2 = from_git_object(repo, oid2) { Tag($0) }
				expect(tag1).notTo(equal(tag2))
			}
		}
		
		describe("hashValue") {
			it("should be equal with equal objects") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let tag1 = from_git_object(repo, oid) { Tag($0) }
				let tag2 = tag1
				expect(tag1.hashValue).to(equal(tag2.hashValue))
			}
		}
	}
}

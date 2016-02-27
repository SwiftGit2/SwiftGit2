//
//  RepositorySpec.swift
//  RepositorySpec
//
//  Created by Matt Diephouse on 11/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Result
import SwiftGit2
import Nimble
import Quick
import Guanaco

class RepositorySpec: QuickSpec {
	override func spec() {
		describe("Repository.Type.atURL()") {
			it("should work if the repo exists") {
				let repo = Fixtures.simpleRepository
				expect(repo.directoryURL).notTo(beNil())
			}
			
			it("should fail if the repo doesn't exist") {
				let url = NSURL(fileURLWithPath: "blah")
				let result = Repository.atURL(url)
				expect(result).to(haveFailed(beAnError(
					domain: equal(libGit2ErrorDomain),
					localizedDescription: match("Failed to resolve path")
				)))
			}
		}

		describe("Reposityory.Type.clone()") {
			it("should handle local clones") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURLForPurpose("local-clone")
				let result = Repository.cloneFromURL(remoteRepo.directoryURL!, toWorkingDirectory: localURL, localClone: true)

				expect(result).to(haveSucceeded())

				if case .Success(let clonedRepo) = result {
					expect(clonedRepo.directoryURL).notTo(beNil())
				}
			}

			it("should handle bare clones") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURLForPurpose("bare-clone")
				let result = Repository.cloneFromURL(remoteRepo.directoryURL!, toWorkingDirectory: localURL, localClone: true, bare: true)

				expect(result).to(haveSucceeded())

				if case .Success(let clonedRepo) = result {
					expect(clonedRepo.directoryURL).to(beNil())
				}
			}

			it("should have set a valid remote url") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURLForPurpose("valid-remote-clone")
				let cloneResult = Repository.cloneFromURL(remoteRepo.directoryURL!, toWorkingDirectory: localURL, localClone: true)

				expect(cloneResult).to(haveSucceeded())

				if case .Success(let clonedRepo) = cloneResult {
					let remoteResult = clonedRepo.remoteWithName("origin")
					expect(remoteResult).to(haveSucceeded())

					if case .Success(let remote) = remoteResult {
						expect(remote.URL).to(equal(remoteRepo.directoryURL?.absoluteString))
					}
				}
			}

			it("should be able to clone a remote repository") {
				let remoteRepoURL = NSURL(string: "https://github.com/libgit2/libgit2.github.com.git")
				let localURL =  self.temporaryURLForPurpose("public-remote-clone")
				let cloneResult = Repository.cloneFromURL(remoteRepoURL!, toWorkingDirectory: localURL)

				expect(cloneResult).to(haveSucceeded())

				if case .Success(let clonedRepo) = cloneResult {
					let remoteResult = clonedRepo.remoteWithName("origin")
					expect(remoteResult).to(haveSucceeded())

					if case .Success(let remote) = remoteResult {
						expect(remote.URL).to(equal(remoteRepoURL?.absoluteString))
					}
				}
			}
		}
		
		describe("Repository.blobWithOID()") {
			it("should return the commit if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let result = repo.blobWithOID(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the blob doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.blobWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a blob") {
				let repo = Fixtures.simpleRepository
				// This is a tree in the repository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.blobWithOID(oid)
				expect(result).to(haveFailed())
			}
		}
		
		describe("Repository.commitWithOID()") {
			it("should return the commit if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.commitWithOID(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the commit doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.commitWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a commit") {
				let repo = Fixtures.simpleRepository
				// This is a tree in the repository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.commitWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.tagWithOID()") {
			it("should return the tag if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let result = repo.tagWithOID(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the tag doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.tagWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a tag") {
				let repo = Fixtures.simpleRepository
				// This is a commit in the repository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.tagWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.treeWithOID()") {
			it("should return the tree if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.treeWithOID(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the tree doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.treeWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a tree") {
				let repo = Fixtures.simpleRepository
				// This is a commit in the repository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.treeWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.objectWithOID()") {
			it("should work with a blob") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				let blob   = repo.blobWithOID(oid).value
				let result = repo.objectWithOID(oid)
				expect(result.map { $0 as! Blob }).to(haveSucceeded(equal(blob)))
			}
			
			it("should work with a commit") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				let commit = repo.commitWithOID(oid).value
				let result = repo.objectWithOID(oid)
				expect(result.map { $0 as! Commit }).to(haveSucceeded(equal(commit)))
			}
			
			it("should work with a tag") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				let tag    = repo.tagWithOID(oid).value
				let result = repo.objectWithOID(oid)
				expect(result.map { $0 as! Tag }).to(haveSucceeded(equal(tag)))
			}
			
			it("should work with a tree") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				let tree   = repo.treeWithOID(oid).value
				let result = repo.objectWithOID(oid)
				expect(result.map { $0 as! Tree }).to(haveSucceeded(equal(tree)))
			}
			
			it("should error if there's no object with that oid") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				let result = repo.objectWithOID(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repsoitory.objectFromPointer(PointerTo)") {
			it("should work with commits") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let pointer = PointerTo<Commit>(oid)
				let commit = repo.commitWithOID(oid).value!
				expect(repo.objectFromPointer(pointer)).to(haveSucceeded(equal(commit)))
			}
			
			it("should work with trees") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let pointer = PointerTo<Tree>(oid)
				let tree = repo.treeWithOID(oid).value!
				expect(repo.objectFromPointer(pointer)).to(haveSucceeded(equal(tree)))
			}
			
			it("should work with blobs") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let pointer = PointerTo<Blob>(oid)
				let blob = repo.blobWithOID(oid).value!
				expect(repo.objectFromPointer(pointer)).to(haveSucceeded(equal(blob)))
			}
			
			it("should work with tags") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let pointer = PointerTo<Tag>(oid)
				let tag = repo.tagWithOID(oid).value!
				expect(repo.objectFromPointer(pointer)).to(haveSucceeded(equal(tag)))
			}
		}
		
		describe("Repository.objectFromPointer(Pointer)") {
			it("should work with commits") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let pointer = Pointer.Commit(oid)
				let commit = repo.commitWithOID(oid).value!
				let result = repo.objectFromPointer(pointer).map { $0 as! Commit }
				expect(result).to(haveSucceeded(equal(commit)))
			}
			
			it("should work with trees") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let pointer = Pointer.Tree(oid)
				let tree = repo.treeWithOID(oid).value!
				let result = repo.objectFromPointer(pointer).map { $0 as! Tree }
				expect(result).to(haveSucceeded(equal(tree)))
			}
			
			it("should work with blobs") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let pointer = Pointer.Blob(oid)
				let blob = repo.blobWithOID(oid).value!
				let result = repo.objectFromPointer(pointer).map { $0 as! Blob }
				expect(result).to(haveSucceeded(equal(blob)))
			}
			
			it("should work with tags") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let pointer = Pointer.Tag(oid)
				let tag = repo.tagWithOID(oid).value!
				let result = repo.objectFromPointer(pointer).map { $0 as! Tag }
				expect(result).to(haveSucceeded(equal(tag)))
			}
		}
		
		describe("Repository.allRemotes()") {
			it("should return an empty list if there are no remotes") {
				let repo = Fixtures.simpleRepository
				let result = repo.allRemotes()
				expect(result).to(haveSucceeded(beEmpty()))
			}
			
			it("should return all the remotes") {
				let repo = Fixtures.mantleRepository
				let remotes = repo.allRemotes()
				let names = remotes.map { $0.map { $0.name } }
				expect(remotes.map { $0.count }).to(haveSucceeded(equal(2)))
				expect(names).to(haveSucceeded(contain("origin", "upstream")))
			}
		}
		
		describe("Repository.remoteWithName()") {
			it("should return the remote if it exists") {
				let repo = Fixtures.mantleRepository
				let result = repo.remoteWithName("upstream")
				expect(result.map { $0.name }).to(haveSucceeded(equal("upstream")))
			}
			
			it("should error if the remote doesn't exist") {
				let repo = Fixtures.simpleRepository
				let result = repo.remoteWithName("nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.referenceWithName()") {
			it("should return a local branch if it exists") {
				let name = "refs/heads/master"
				let result = Fixtures.simpleRepository.referenceWithName(name)
				expect(result.map { $0.longName }).to(haveSucceeded(equal(name)))
				expect(result.value as? Branch).notTo(beNil())
			}

			it("should return a remote branch if it exists") {
				let name = "refs/remotes/upstream/master"
				let result = Fixtures.mantleRepository.referenceWithName(name)
				expect(result.map { $0.longName }).to(haveSucceeded(equal(name)))
				expect(result.value as? Branch).notTo(beNil())
			}
			
			it("should return a tag if it exists") {
				let name = "refs/tags/tag-2"
				let result = Fixtures.simpleRepository.referenceWithName(name)
				expect(result.value?.longName).to(equal(name))
				expect(result.value as? TagReference).notTo(beNil())
			}
			
			it("should return the reference if it exists") {
				let name = "refs/other-ref"
				let result = Fixtures.simpleRepository.referenceWithName(name)
				expect(result.value?.longName).to(equal(name))
			}
			
			it("should error if the reference doesn't exist") {
				let result = Fixtures.simpleRepository.referenceWithName("refs/heads/nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.localBranches()") {
			it("should return all the local branches") {
				let repo = Fixtures.simpleRepository
				let expected = [
					repo.localBranchWithName("another-branch").value!,
					repo.localBranchWithName("master").value!,
					repo.localBranchWithName("yet-another-branch").value!,
				]
				expect(repo.localBranches().value).to(equal(expected))
			}
		}
		
		describe("Repository.remoteBranches()") {
			it("should return all the remote branches") {
				let repo = Fixtures.mantleRepository
				let expectedNames = [
					"origin/2.0-development",
					"origin/HEAD",
					"origin/bump-config",
					"origin/bump-xcconfigs",
					"origin/github-reversible-transformer",
					"origin/master",
					"origin/mtlmanagedobject",
					"origin/reversible-transformer",
					"origin/subclassing-notes",
					"upstream/2.0-development",
					"upstream/bump-config",
					"upstream/bump-xcconfigs",
					"upstream/github-reversible-transformer",
					"upstream/master",
					"upstream/mtlmanagedobject",
					"upstream/reversible-transformer",
					"upstream/subclassing-notes",
				]
				let expected = expectedNames.map { repo.remoteBranchWithName($0).value! }
				let actual = repo.remoteBranches().value!.sort {
					return $0.longName.characters.lexicographicalCompare($1.longName.characters)
				}
				expect(actual).to(equal(expected))
				expect(actual.map { $0.name }).to(equal(expectedNames))
			}
		}
		
		describe("Repository.localBranchWithName()") {
			it("should return the branch if it exists") {
				let result = Fixtures.simpleRepository.localBranchWithName("master")
				expect(result.value?.longName).to(equal("refs/heads/master"))
			}
			
			it("should error if the branch doesn't exists") {
				let result = Fixtures.simpleRepository.localBranchWithName("nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.remoteBranchWithName()") {
			it("should return the branch if it exists") {
				let result = Fixtures.mantleRepository.remoteBranchWithName("upstream/master")
				expect(result.value?.longName).to(equal("refs/remotes/upstream/master"))
			}
			
			it("should error if the branch doesn't exists") {
				let result = Fixtures.simpleRepository.remoteBranchWithName("origin/nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.allTags()") {
			it("should return all the tags") {
				let repo = Fixtures.simpleRepository
				let expected = [
					repo.tagWithName("tag-1").value!,
					repo.tagWithName("tag-2").value!,
				]
				expect(repo.allTags().value).to(equal(expected))
			}
		}
		
		describe("Repository.tagWithName()") {
			it("should return the tag if it exists") {
				let result = Fixtures.simpleRepository.tagWithName("tag-2")
				expect(result.value?.longName).to(equal("refs/tags/tag-2"))
			}
			
			it("should error if the branch doesn't exists") {
				let result = Fixtures.simpleRepository.tagWithName("nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.HEAD()") {
			it("should work when on a branch") {
				let result = Fixtures.simpleRepository.HEAD()
				expect(result.value?.longName).to(equal("refs/heads/master"))
				expect(result.value?.shortName).to(equal("master"))
				expect(result.value as? Branch).notTo(beNil())
			}
			
			it("should work when on a detached HEAD") {
				let result = Fixtures.detachedHeadRepository.HEAD()
				expect(result.value?.longName).to(equal("HEAD"))
				expect(result.value?.shortName).to(beNil())
				expect(result.value?.oid).to(equal(OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e")!))
				expect(result.value as? Reference).notTo(beNil())
			}
		}
		
		describe("Repository.setHEAD(OID)") {
			it("should set HEAD to the OID") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e")!
				expect(repo.HEAD().value?.shortName).to(equal("master"))
				
				expect(repo.setHEAD(oid)).to(haveSucceeded())
				let HEAD = repo.HEAD().value
				expect(HEAD?.longName).to(equal("HEAD"))
				expect(HEAD?.oid).to(equal(oid))
				
				expect(repo.setHEAD(repo.localBranchWithName("master").value!)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal("master"))
			}
		}
		
		describe("Repository.setHEAD(ReferenceType)") {
			it("should set HEAD to a branch") {
				let repo = Fixtures.detachedHeadRepository
				let oid = repo.HEAD().value!.oid
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
				
				let branch = repo.localBranchWithName("another-branch").value!
				expect(repo.setHEAD(branch)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal(branch.name))
				
				expect(repo.setHEAD(oid)).to(haveSucceeded())
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
			}
		}
		
		describe("Repository.checkout()") {
			// We're not really equipped to test this yet. :(
		}
		
		describe("Repository.checkout(OID)") {
			it("should set HEAD") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e")!
				expect(repo.HEAD().value?.shortName).to(equal("master"))
				
				expect(repo.checkout(oid, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				let HEAD = repo.HEAD().value
				expect(HEAD?.longName).to(equal("HEAD"))
				expect(HEAD?.oid).to(equal(oid))
				
				expect(repo.checkout(repo.localBranchWithName("master").value!, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal("master"))
			}
		}
		
		describe("Repository.checkout(ReferenceType)") {
			it("should set HEAD") {
				let repo = Fixtures.detachedHeadRepository
				let oid = repo.HEAD().value!.oid
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
				
				let branch = repo.localBranchWithName("another-branch").value!
				expect(repo.checkout(branch, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal(branch.name))
				
				expect(repo.checkout(oid, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
			}
		}
	}

	func temporaryURLForPurpose(purpose: String) -> NSURL {
		let globallyUniqueString = NSProcessInfo.processInfo().globallyUniqueString
		let path = "\(NSTemporaryDirectory())\(globallyUniqueString)_\(purpose)"
		return NSURL(fileURLWithPath: path)
	}
}

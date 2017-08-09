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
		describe("Repository.Type.at(_:)") {
			it("should work if the repo exists") {
				let repo = Fixtures.simpleRepository
				expect(repo.directoryURL).notTo(beNil())
			}
			
			it("should fail if the repo doesn't exist") {
				let url = URL(fileURLWithPath: "blah")
				let result = Repository.at(url)
				expect(result).to(haveFailed(beAnError(
					domain: equal(libGit2ErrorDomain),
					localizedDescription: match("Failed to resolve path")
				)))
			}
		}

		describe("Repository.Type.create(at:)") {
			it("should create a new repo at the specified location") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURL(forPurpose: "local-create")
				let result = Repository.create(at: localURL)

				expect(result).to(haveSucceeded())

				if case .success(let clonedRepo) = result {
					expect(clonedRepo.directoryURL).notTo(beNil())
				}
			}
		}

		describe("Repository.Type.clone(from:to:)") {
			it("should handle local clones") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURL(forPurpose: "local-clone")
				let result = Repository.clone(from: remoteRepo.directoryURL!, to: localURL, localClone: true)
				
				expect(result).to(haveSucceeded())
				
				if case .success(let clonedRepo) = result {
					expect(clonedRepo.directoryURL).notTo(beNil())
				}
			}
			
			it("should handle bare clones") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURL(forPurpose: "bare-clone")
				let result = Repository.clone(from: remoteRepo.directoryURL!, to: localURL, localClone: true, bare: true)
				
				expect(result).to(haveSucceeded())
				
				if case .success(let clonedRepo) = result {
					expect(clonedRepo.directoryURL).to(beNil())
				}
			}
			
			it("should have set a valid remote url") {
				let remoteRepo = Fixtures.simpleRepository
				let localURL = self.temporaryURL(forPurpose: "valid-remote-clone")
				let cloneResult = Repository.clone(from: remoteRepo.directoryURL!, to: localURL, localClone: true)
				
				expect(cloneResult).to(haveSucceeded())
				
				if case .success(let clonedRepo) = cloneResult {
					let remoteResult = clonedRepo.remote(named: "origin")
					expect(remoteResult).to(haveSucceeded())
					
					if case .success(let remote) = remoteResult {
						expect(remote.URL).to(equal(remoteRepo.directoryURL?.absoluteString))
					}
				}
			}
			
			it("should be able to clone a remote repository") {
				let remoteRepoURL = URL(string: "https://github.com/libgit2/libgit2.github.com.git")
				let localURL = self.temporaryURL(forPurpose: "public-remote-clone")
				let cloneResult = Repository.clone(from: remoteRepoURL!, to: localURL)
				
				expect(cloneResult).to(haveSucceeded())
				
				if case .success(let clonedRepo) = cloneResult {
					let remoteResult = clonedRepo.remote(named: "origin")
					expect(remoteResult).to(haveSucceeded())
					
					if case .success(let remote) = remoteResult {
						expect(remote.URL).to(equal(remoteRepoURL?.absoluteString))
					}
				}
			}
			
			let env = ProcessInfo.processInfo.environment
			
			if let privateRepo = env["SG2TestPrivateRepo"],
			   let gitUsername = env["SG2TestUsername"],
			   let publicKey = env["SG2TestPublicKey"],
			   let privateKey = env["SG2TestPrivateKey"],
			   let passphrase = env["SG2TestPassphrase"] {
				
				it("should be able to clone a remote repository requiring credentials") {
					let remoteRepoURL = URL(string: privateRepo)
					let localURL = self.temporaryURL(forPurpose: "private-remote-clone")
					let credentials = Credentials.sshMemory(username: gitUsername,
						publicKey: publicKey,
						privateKey: privateKey,
						passphrase: passphrase)
					
					let cloneResult = Repository.clone(from: remoteRepoURL!, to: localURL, credentials: credentials)
					
					expect(cloneResult).to(haveSucceeded())
					
					if case .success(let clonedRepo) = cloneResult {
						let remoteResult = clonedRepo.remote(named: "origin")
						expect(remoteResult).to(haveSucceeded())
						
						if case .success(let remote) = remoteResult {
							expect(remote.URL).to(equal(remoteRepoURL?.absoluteString))
						}
					}
				}
			}
		}
		
		describe("Repository.blob(_:)") {
			it("should return the commit if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let result = repo.blob(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the blob doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.blob(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a blob") {
				let repo = Fixtures.simpleRepository
				// This is a tree in the repository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.blob(oid)
				expect(result).to(haveFailed())
			}
		}
		
		describe("Repository.commit(_:)") {
			it("should return the commit if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.commit(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the commit doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.commit(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a commit") {
				let repo = Fixtures.simpleRepository
				// This is a tree in the repository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.commit(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.tag(_:)") {
			it("should return the tag if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let result = repo.tag(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the tag doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.tag(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a tag") {
				let repo = Fixtures.simpleRepository
				// This is a commit in the repository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.tag(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.tree(_:)") {
			it("should return the tree if it exists") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let result = repo.tree(oid)
				expect(result.map { $0.oid }).to(haveSucceeded(equal(oid)))
			}
			
			it("should error if the tree doesn't exist") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				
				let result = repo.tree(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
			
			it("should error if the oid doesn't point to a tree") {
				let repo = Fixtures.simpleRepository
				// This is a commit in the repository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let result = repo.tree(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.object(_:)") {
			it("should work with a blob") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				let blob   = repo.blob(oid).value
				let result = repo.object(oid)
				expect(result.map { $0 as! Blob }).to(haveSucceeded(equal(blob)))
			}
			
			it("should work with a commit") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				let commit = repo.commit(oid).value
				let result = repo.object(oid)
				expect(result.map { $0 as! Commit }).to(haveSucceeded(equal(commit)))
			}
			
			it("should work with a tag") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				let tag    = repo.tag(oid).value
				let result = repo.object(oid)
				expect(result.map { $0 as! Tag }).to(haveSucceeded(equal(tag)))
			}
			
			it("should work with a tree") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				let tree   = repo.tree(oid).value
				let result = repo.object(oid)
				expect(result.map { $0 as! Tree }).to(haveSucceeded(equal(tree)))
			}
			
			it("should error if there's no object with that oid") {
				let repo   = Fixtures.simpleRepository
				let oid    = OID(string: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")!
				let result = repo.object(oid)
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.object(from: PointerTo)") {
			it("should work with commits") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let pointer = PointerTo<Commit>(oid)
				let commit = repo.commit(oid).value!
				expect(repo.object(from: pointer)).to(haveSucceeded(equal(commit)))
			}
			
			it("should work with trees") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let pointer = PointerTo<Tree>(oid)
				let tree = repo.tree(oid).value!
				expect(repo.object(from: pointer)).to(haveSucceeded(equal(tree)))
			}
			
			it("should work with blobs") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let pointer = PointerTo<Blob>(oid)
				let blob = repo.blob(oid).value!
				expect(repo.object(from: pointer)).to(haveSucceeded(equal(blob)))
			}
			
			it("should work with tags") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let pointer = PointerTo<Tag>(oid)
				let tag = repo.tag(oid).value!
				expect(repo.object(from: pointer)).to(haveSucceeded(equal(tag)))
			}
		}
		
		describe("Repository.object(from: Pointer)") {
			it("should work with commits") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "dc220a3f0c22920dab86d4a8d3a3cb7e69d6205a")!
				
				let pointer = Pointer.commit(oid)
				let commit = repo.commit(oid).value!
				let result = repo.object(from: pointer).map { $0 as! Commit }
				expect(result).to(haveSucceeded(equal(commit)))
			}
			
			it("should work with trees") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "f93e3a1a1525fb5b91020da86e44810c87a2d7bc")!
				
				let pointer = Pointer.tree(oid)
				let tree = repo.tree(oid).value!
				let result = repo.object(from: pointer).map { $0 as! Tree }
				expect(result).to(haveSucceeded(equal(tree)))
			}
			
			it("should work with blobs") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "41078396f5187daed5f673e4a13b185bbad71fba")!
				
				let pointer = Pointer.blob(oid)
				let blob = repo.blob(oid).value!
				let result = repo.object(from: pointer).map { $0 as! Blob }
				expect(result).to(haveSucceeded(equal(blob)))
			}
			
			it("should work with tags") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "57943b8ee00348180ceeedc960451562750f6d33")!
				
				let pointer = Pointer.tag(oid)
				let tag = repo.tag(oid).value!
				let result = repo.object(from: pointer).map { $0 as! Tag }
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
		
		describe("Repository.remote(named:)") {
			it("should return the remote if it exists") {
				let repo = Fixtures.mantleRepository
				let result = repo.remote(named: "upstream")
				expect(result.map { $0.name }).to(haveSucceeded(equal("upstream")))
			}
			
			it("should error if the remote doesn't exist") {
				let repo = Fixtures.simpleRepository
				let result = repo.remote(named: "nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.reference(named:)") {
			it("should return a local branch if it exists") {
				let name = "refs/heads/master"
				let result = Fixtures.simpleRepository.reference(named: name)
				expect(result.map { $0.longName }).to(haveSucceeded(equal(name)))
				expect(result.value as? Branch).notTo(beNil())
			}
			
			it("should return a remote branch if it exists") {
				let name = "refs/remotes/upstream/master"
				let result = Fixtures.mantleRepository.reference(named: name)
				expect(result.map { $0.longName }).to(haveSucceeded(equal(name)))
				expect(result.value as? Branch).notTo(beNil())
			}
			
			it("should return a tag if it exists") {
				let name = "refs/tags/tag-2"
				let result = Fixtures.simpleRepository.reference(named: name)
				expect(result.value?.longName).to(equal(name))
				expect(result.value as? TagReference).notTo(beNil())
			}
			
			it("should return the reference if it exists") {
				let name = "refs/other-ref"
				let result = Fixtures.simpleRepository.reference(named: name)
				expect(result.value?.longName).to(equal(name))
			}
			
			it("should error if the reference doesn't exist") {
				let result = Fixtures.simpleRepository.reference(named: "refs/heads/nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.localBranches()") {
			it("should return all the local branches") {
				let repo = Fixtures.simpleRepository
				let expected = [
					repo.localBranch(named: "another-branch").value!,
					repo.localBranch(named: "master").value!,
					repo.localBranch(named: "yet-another-branch").value!,
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
				let expected = expectedNames.map { repo.remoteBranch(named: $0).value! }
				let actual = repo.remoteBranches().value!.sorted {
					return $0.longName.characters.lexicographicallyPrecedes($1.longName.characters)
				}
				expect(actual).to(equal(expected))
				expect(actual.map { $0.name }).to(equal(expectedNames))
			}
		}
		
		describe("Repository.localBranch(named:)") {
			it("should return the branch if it exists") {
				let result = Fixtures.simpleRepository.localBranch(named: "master")
				expect(result.value?.longName).to(equal("refs/heads/master"))
			}
			
			it("should error if the branch doesn't exists") {
				let result = Fixtures.simpleRepository.localBranch(named: "nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.remoteBranch(named:)") {
			it("should return the branch if it exists") {
				let result = Fixtures.mantleRepository.remoteBranch(named: "upstream/master")
				expect(result.value?.longName).to(equal("refs/remotes/upstream/master"))
			}
			
			it("should error if the branch doesn't exists") {
				let result = Fixtures.simpleRepository.remoteBranch(named: "origin/nonexistent")
				expect(result).to(haveFailed(beAnError(domain: equal(libGit2ErrorDomain))))
			}
		}
		
		describe("Repository.allTags()") {
			it("should return all the tags") {
				let repo = Fixtures.simpleRepository
				let expected = [
					repo.tag(named: "tag-1").value!,
					repo.tag(named: "tag-2").value!,
				]
				expect(repo.allTags().value).to(equal(expected))
			}
		}
		
		describe("Repository.tag(named:)") {
			it("should return the tag if it exists") {
				let result = Fixtures.simpleRepository.tag(named: "tag-2")
				expect(result.value?.longName).to(equal("refs/tags/tag-2"))
			}
			
			it("should error if the branch doesn't exists") {
				let result = Fixtures.simpleRepository.tag(named: "nonexistent")
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
				
				expect(repo.setHEAD(repo.localBranch(named: "master").value!)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal("master"))
			}
		}
		
		describe("Repository.setHEAD(ReferenceType)") {
			it("should set HEAD to a branch") {
				let repo = Fixtures.detachedHeadRepository
				let oid = repo.HEAD().value!.oid
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
				
				let branch = repo.localBranch(named: "another-branch").value!
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
				
				expect(repo.checkout(repo.localBranch(named: "master").value!, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal("master"))
			}
			
			it("should call block on progress") {
				let repo = Fixtures.simpleRepository
				let oid = OID(string: "315b3f344221db91ddc54b269f3c9af422da0f2e")!
				expect(repo.HEAD().value?.shortName).to(equal("master"))
				
				expect(repo.checkout(oid, strategy: .None, progress: { (_, completedSteps, totalSteps) -> Void in
					expect(completedSteps).to(beLessThanOrEqualTo(totalSteps))
				})).to(haveSucceeded())
				
				let HEAD = repo.HEAD().value
				expect(HEAD?.longName).to(equal("HEAD"))
				expect(HEAD?.oid).to(equal(oid))
			}
		}
		
		describe("Repository.checkout(ReferenceType)") {
			it("should set HEAD") {
				let repo = Fixtures.detachedHeadRepository
				let oid = repo.HEAD().value!.oid
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
				
				let branch = repo.localBranch(named: "another-branch").value!
				expect(repo.checkout(branch, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				expect(repo.HEAD().value?.shortName).to(equal(branch.name))
				
				expect(repo.checkout(oid, strategy: CheckoutStrategy.None)).to(haveSucceeded())
				expect(repo.HEAD().value?.longName).to(equal("HEAD"))
			}
		}
		
		describe("Repository.allCommits(in:)") {
			it("should return all (9) commits") {
				let repo = Fixtures.simpleRepository
				let branches = repo.localBranches().value!
				let expectedCount = 9
				let expectedMessages: [String] = [
					"List branches in README\n",
					"Create a README\n",
					"Merge branch 'alphabetize'\n",
					"Alphabetize branches\n",
					"List new branches\n",
					"List branches in README\n",
					"Create a README\n",
					"List branches in README\n",
					"Create a README\n"
				]
				var commitMessages: [String] = []
				for branch in branches {
					for commit in repo.commits(in: branch) {
						commitMessages.append(commit.value!.message)
					}
				}
				expect(commitMessages.count).to(equal(expectedCount))
				expect(commitMessages).to(equal(expectedMessages))
			}
		}
	}
	
	func temporaryURL(forPurpose purpose: String) -> URL {
		let globallyUniqueString = ProcessInfo.processInfo.globallyUniqueString
		let path = "\(NSTemporaryDirectory())\(globallyUniqueString)_\(purpose)"
		return URL(fileURLWithPath: path)
	}
}

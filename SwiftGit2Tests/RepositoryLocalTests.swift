
import Foundation
import XCTest
import Essentials
@testable import SwiftGit2


class RepositoryLocalTests: XCTestCase {
    
    func testCreateOpenRepo() throws {
        GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .assertFailure("create repo")
    }
    
    func testCreateAddFile() throws {
        GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .flatMap { $0.t_commit(msg: "initial commit") }
            .assertFailure("initial commit")
    }
    
    func testCreateRepo() {
        let url = GitTest.localRoot.appendingPathComponent("NewRepo")
        let README_md = "README.md"
        url.rm().assertFailure("rm")
        
        guard let repo = Repository.create(at: url).assertFailure("Repository.create") else { fatalError() }
        
        let file = url.appendingPathComponent(README_md)
        "# test repository".write(to: file).assertFailure("write file")
        
        //if let status = repo.status().assertFailure("status") { XCTAssert(status.count == 1) } else { fatalError() }
        
        //repo.reset(paths: )
        repo.index().flatMap { $0.add(paths: [README_md]) }
            .assertFailure("index add \(README_md)")
        
        repo.commit(message: "initial commit", signature: Signature(name: "name", email: "email@domain.com"))
            .assertFailure("initial commit")
    }
    
    func testDetachedHead() throws {
        let repo_ = GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .assertFailure("create repo")
        
        // for some reason it doesnt compile "let repo = repo"
        guard let repo = repo_ else { fatalError() }
        
        // HEAD is unborn
        XCTAssert(repo.headIsUnborn)
        guard let fixResultUnborn = repo.detachedHeadFix().assertFailure("detached HEAD fix on unborn") else { fatalError() }
        XCTAssert(fixResultUnborn == .notNecessary)
        
        // single commit
        repo.t_commit(msg: "commit1").assertFailure("commit")
        XCTAssert(!repo.headIsUnborn)
        guard let fixResultWCommit = repo.detachedHeadFix().assertFailure("detached HEAD fix on commit1") else { fatalError() }
        XCTAssert(fixResultWCommit == .notNecessary)
        
        repo.detachHEAD()
            .assertFailure("set HEAD detached")
        
        guard let fixResultDetached = repo.detachedHeadFix().assertFailure("detached HEAD fix") else { fatalError() }
        XCTAssert(fixResultDetached == .fixed)
        
        repo.createBranch(from: .head, name: "branch1", checkout: false)
            .assertFailure("create branch1")
        
        repo.detachHEAD()
            .assertFailure("set HEAD detached")
        
        guard let fixResultAmbigues = repo.detachedHeadFix().assertFailure("detached HEAD fix") else { fatalError() }
        
        XCTAssert(fixResultAmbigues == .ambiguous(branches: ["refs/heads/branch1", "refs/heads/master"]))
    }
}

extension Repository {
    func detachHEAD() -> Result<(), Error> {
        HEAD()
            .flatMap { $0.commitOID }
            .flatMap { self.setHEAD_detached($0) }
    }
}

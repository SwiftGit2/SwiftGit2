
import XCTest
@testable import SwiftGit2
import Essentials


class MergeAnalysisTests: XCTestCase {
    
    func testFastForward() throws {
        let info = PublicTestRepo()

        guard let repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
                .assertFailure("clone 1") else { fatalError() }

        guard let repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
                .assertFailure("clone 2") else { fatalError() }

        //
        // FAST FORWARD MERGE
        //
        repo2.t_commit(file: .fileA, with: .random, msg: "for FAST FORWARD MERGE Test")
            .assertFailure("t_commit")
        repo2.push()
            .assertFailure("push")

        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: .upToDate, "merge analysis")
        
        repo1.fetch(.HEAD)
            .assertFailure("fetch")
        
        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: [.fastForward, .normal], "merge analysis")
        
        repo1.pull(signature: GitTest.signature)
            .assertEqual(to: .fastForward, "merge analysis")
    }
    
    func testThreWay() throws {
        let info = PublicTestRepo()

        guard let repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
                .assertFailure("clone 1") else { fatalError() }

        guard let repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
                .assertFailure("clone 2") else { fatalError() }
        
        //
        // THREE WAY SUCCESSFUL MERGE
        //
        repo2.t_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
            .assertFailure("t_commit")
        repo2.push()
            .assertFailure("push")
        
        repo1.t_commit(file: .fileB, with: .random, msg: "[OUR] for THREE WAY SUCCESSFUL MERGE test")
            .assertFailure("t_commit")
        
        repo1.fetch(.HEAD)
            .assertFailure("fetch")
        
        let merge = repo1.mergeAnalysis(.HEAD)
            .assertNotEqual(to: [.fastForward], "merge analysis")
        
        XCTAssert(merge == .normal)
        
        repo1.pull(signature: GitTest.signature)
            .assertBlock { $0 == .threeWaySuccess }
        
        //repo1
        //repo2.push(remoteRepoName: <#T##String#>, localBranchName: <#T##String#>, auth: <#T##Auth#>)

        print(repo1, repo2)
    }
    
}

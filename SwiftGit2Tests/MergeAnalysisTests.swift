
import XCTest
@testable import SwiftGit2
import Essentials


class MergeAnalysisTests: XCTestCase {
    
    func testUpToDate() throws {
        let info = PublicTestRepo()
        
        guard let repo = Repository.clone(from: info.urlSsh, to: info.localPath)
                .assertFailure("clone") else { fatalError() }
        
        repo.mergeAnalysis(.HEAD)
            .assertEqual(to: .upToDate, "merge analysis")
    }
    
    func testNormal() throws {
        let info = PublicTestRepo()

        guard let repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
                .assertFailure("clone 1") else { fatalError() }

        guard let repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
                .assertFailure("clone 2") else { fatalError() }

        repo2.t_commit(file: .fileA, with: .random, msg: "fileA commit")
            .assertFailure("t_commit")
        repo2.push()
            .assertFailure("push")

        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: .upToDate, "merge analysis")
        
        repo1.fetch(.HEAD)
            .assertFailure("fetch")
        
        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: [.fastForward, .normal], "merge analysis")
        
        //repo1
        //repo2.push(remoteRepoName: <#T##String#>, localBranchName: <#T##String#>, auth: <#T##Auth#>)

        print(repo1, repo2)
    }
    
}

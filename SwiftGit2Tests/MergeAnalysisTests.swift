
import XCTest
@testable import SwiftGit2
import Essentials


class MergeAnalysisTests: XCTestCase {
    
    func testUpToDate() throws {
        let info = PublicTestRepo()
        
        guard let repo = Repository.clone(from: info.urlSsh, to: info.localPath)
                .assertFailure("clone") else { fatalError() }
        
        repo.HEAD()
            .flatMap { $0.asBranch() }
            .flatMap { $0.upstream() }
            .flatMap { $0.commitOID }
            .flatMap { repo.annotatedCommit(oid: $0) }
            .flatMap { repo.mergeAnalysis(their_head: $0) }
            .assertEqual(to: .upToDate, "merge analysis")
    }
    
//    func testNormal() throws {
//        let info = PublicTestRepo()
//        
//        guard let repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
//                .assertFailure("clone 1") else { fatalError() }
//        
//        guard let repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
//                .assertFailure("clone 2") else { fatalError() }
//        
//        repo2.t_write(file: .fileA, with: .random)
//            .assertFailure("t_write")
//        
//        //repo2.push(remoteRepoName: <#T##String#>, localBranchName: <#T##String#>, auth: <#T##Auth#>)
//        
//        print(repo1, repo2)
//    }
    
}

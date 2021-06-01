
import Essentials
@testable import SwiftGit2
import XCTest

class MergeAnalysisTests: XCTestCase {
    var repo1: Repository!
    var repo2: Repository!

    override func setUpWithError() throws {
        let info = PublicTestRepo()

        repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
            .assertFailure("clone 1")

        repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
            .assertFailure("clone 2")
    }

    override func tearDownWithError() throws {}

    func testFastForward() throws {
        repo2.t_push_commit(file: .fileA, with: .random, msg: "for FAST FORWARD MERGE Test")
            .assertFailure()

        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: .upToDate)

        repo1.fetch(.HEAD)
            .assertFailure()

        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: [.fastForward, .normal])

        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertEqual(to: .fastForward, "pull fast forward merge")
    }

    func testThreWaySuccess() throws {
        repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()

        repo1.t_commit(file: .fileB, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()

        repo1.fetch(.HEAD)
            .assertFailure()

        let merge = repo1.mergeAnalysis(.HEAD)
            .assertNotEqual(to: [.fastForward], "merge analysis")

        XCTAssert(merge == .normal)

        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertEqual(to: .threeWaySuccess)
    }

    func testThreeWayConflict() throws {
        // fileA
        repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()

        // Same fileA
        repo1.t_commit(file: .fileA, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()

        repo1.fetch(.HEAD)
            .assertFailure()

        let merge = repo1.mergeAnalysis(.HEAD)
            .assertNotEqual(to: [.fastForward])

        XCTAssert(merge == .normal)

        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertBlock("pull has conflict") { $0.hasConflict }
    }
}

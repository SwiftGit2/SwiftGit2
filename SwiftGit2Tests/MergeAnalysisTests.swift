//
//  AnalyzeMergeTests.swift
//  SwiftGit2Tests
//
//  Created by loki on 24.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

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

}

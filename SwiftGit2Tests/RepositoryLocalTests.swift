//
//  RepositoryLocalTests.swift
//  SwiftGit2Tests
//
//  Created by loki on 24.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import XCTest
import Essentials
@testable import SwiftGit2


class RepositoryLocalTests: XCTestCase {
	func testCreateOpenRepo() {
		let url = try? URL.randomTempDirectory().get()
		print(url ?? "nil")
		URL.randomTempDirectory()
			.flatMap { Repository.create(at: $0) }
			.assertFailure("create repo")
	}

}

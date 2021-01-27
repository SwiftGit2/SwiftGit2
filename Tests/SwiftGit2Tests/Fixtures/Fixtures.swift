//
//  Fixtures.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import SwiftGit2
import Zip

final class Fixtures {

	// MARK: Lifecycle

	class var sharedInstance: Fixtures {
		enum Singleton {
			static let instance = Fixtures()
		}
		return Singleton.instance
	}

	init() {
		directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.appendingPathComponent("org.libgit2.SwiftGit2")
			.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
	}

	// MARK: - Setup and Teardown

	let directoryURL: URL

	func setUp() {
		try! FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

		let zipURLs = Bundle.module.urls(forResourcesWithExtension: "zip", subdirectory: nil)!
		assert(!zipURLs.isEmpty, "No zip-files for testing found.")
		for url in zipURLs {
			// Will throw error but everything will be fine. Does not happen when using SwiftPM.
			try? Zip.unzipFile(url as URL, destination: directoryURL, overwrite: true, password: nil)
		}
	}

	func tearDown() {
		try? FileManager.default.removeItem(at: directoryURL)
	}

	// MARK: - Helpers

	func repository(named name: String) -> Repository {
		let url = directoryURL.appendingPathComponent(name, isDirectory: true)
		switch Repository.at(url) {
		case .success(let repo):
			return repo
		case .failure(let error):
			fatalError(error.localizedDescription)
		}
	}

	// MARK: - The Fixtures

	class var detachedHeadRepository: Repository {
		return Fixtures.sharedInstance.repository(named: "detached-head")
	}

	class var simpleRepository: Repository {
		return Fixtures.sharedInstance.repository(named: "simple-repository")
	}

	class var mantleRepository: Repository {
		return Fixtures.sharedInstance.repository(named: "Mantle")
	}
}

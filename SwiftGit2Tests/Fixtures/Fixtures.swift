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

		#if SWIFT_PACKAGE
			//let bundle = Bundle.module // crashes Swift 5.3 beta (5.3-DEVELOPMENT-SNAPSHOT-2020-05-11-a)
			let bundleURL = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") })!.bundleURL
			let bundle =
				Bundle(url: bundleURL.deletingLastPathComponent().appendingPathComponent("SwiftGit2_SwiftGit2Tests.bundle"))!
		#else
			#if os(OSX)
			let platform = "OSX"
			#else
			let platform = "iOS"
			#endif
			let bundleIdentifier = String(format: "org.libgit2.SwiftGit2-%@Tests", arguments: [platform])
			let bundle = Bundle(identifier: bundleIdentifier)!
		#endif

		let zipURLs = bundle.urls(forResourcesWithExtension: "zip", subdirectory: nil)!
		assert(!zipURLs.isEmpty, "No zip-files for testing found.")
		for url in zipURLs {
			// Will throw error but everything will be fine. Does not happen when using SwiftPM.
			try? Zip.unzipFile(url, destination: directoryURL, overwrite: true, password: nil)
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

//
//  Fixtures.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import SwiftGit2
import ZIPFoundation

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
		let fileManager = FileManager.default
		try! fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
		let bundle = Bundle(for: Fixtures.self)
		let zipURLs = bundle.urls(forResourcesWithExtension: "zip", subdirectory: nil)!
		for URL in zipURLs {
			do {
				try fileManager.unzipItem(at: URL, to: directoryURL)
			} catch {
				print(error.localizedDescription)
			}
		}
	}

	func tearDown() {
		try! FileManager.default.removeItem(at: directoryURL)
	}

	// MARK: - Helpers

	func repository(named name: String) -> Repository {
		let url = directoryURL.appendingPathComponent(name, isDirectory: true)
		return Repository.at(url).value!
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

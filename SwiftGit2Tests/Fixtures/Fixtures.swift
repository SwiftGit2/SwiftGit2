//
//  Fixtures.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import SwiftGit2
import ZipArchive

final class Fixtures {
	
	// MARK: Lifecycle
	
	class var sharedInstance: Fixtures {
		struct Singleton {
			static let instance = Fixtures()
		}
		return Singleton.instance
	}
	
	init() {
		directoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
			.URLByAppendingPathComponent("org.libgit2.SwiftGit2")!
			.URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)!
	}
	
	// MARK: - Setup and Teardown
	
	let directoryURL: NSURL
	
	func setUp() {
		try! NSFileManager.defaultManager().createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil)

		#if os(OSX)
			let platform = "OSX"
		#else
			let platform = "iOS"
		#endif
		let bundleIdentifier = String(format: "org.libgit2.SwiftGit2-%@Tests", arguments: [platform])
		let bundle = NSBundle(identifier: bundleIdentifier)!
		let zipURLs = bundle.URLsForResourcesWithExtension("zip", subdirectory: nil)! as [NSURL]
		
		for URL in zipURLs {
			SSZipArchive.unzipFileAtPath(URL.path!, toDestination: directoryURL.path!)
		}
	}
	
	func tearDown() {
		try! NSFileManager.defaultManager().removeItemAtURL(directoryURL)
	}
	
	// MARK: - Helpers
	
	func repositoryWithName(name: String) -> Repository {
		let url = directoryURL.URLByAppendingPathComponent(name, isDirectory: true)!
		return Repository.atURL(url).value!
	}
	
	// MARK: - The Fixtures
	
	class var detachedHeadRepository: Repository {
		return Fixtures.sharedInstance.repositoryWithName("detached-head")
	}
	
	class var simpleRepository: Repository {
		return Fixtures.sharedInstance.repositoryWithName("simple-repository")
	}
	
	class var mantleRepository: Repository {
		return Fixtures.sharedInstance.repositoryWithName("Mantle")
	}
}

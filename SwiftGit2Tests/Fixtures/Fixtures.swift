//
//  Fixtures.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/16/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import SwiftGit2

final class Fixtures {
	
	// MARK: Lifecycle
	
	class var sharedInstance: Fixtures {
		struct Singleton {
			static let instance = Fixtures()
		}
		return Singleton.instance
	}
	
	init() {
		let path = NSTemporaryDirectory()
			.stringByAppendingPathComponent("org.libgit2.SwiftGit2")
			.stringByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
		directoryURL = NSURL.fileURLWithPath(path, isDirectory: true)!
	}
	
	// MARK: - Setup and Teardown
	
	let directoryURL: NSURL
	
	func setUp() {
		NSFileManager.defaultManager().createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil, error: nil)

		#if os(OSX)
			let platform = "OSX"
		#else
			let platform = "iOS"
		#endif
		let bundleIdentifier = String(format: "org.libgit2.SwiftGit2-%@Tests", arguments: [platform])
		let bundle = NSBundle(identifier: bundleIdentifier)!
		let zipURLs = bundle.URLsForResourcesWithExtension("zip", subdirectory: nil)! as! [NSURL]
		
		for URL in zipURLs {
			unzipFileAtURL(URL, intoDirectoryAtURL: directoryURL)
		}
	}
	
	func tearDown() {
		NSFileManager.defaultManager().removeItemAtURL(directoryURL, error: nil)
	}
	
	func unzipFileAtURL(fileURL: NSURL, intoDirectoryAtURL directoryURL: NSURL) {
        #if os(OSX)

            let task = NSTask()
            task.launchPath = "/usr/bin/unzip"
            task.arguments = [ "-qq", "-d", directoryURL.path!, fileURL.path! ]
            
            task.launch()
            task.waitUntilExit()

        #else

            assertionFailure("Tests not supported on iOS yet")

        #endif
	}
	
	// MARK: - Helpers
	
	func repositoryWithName(name: String) -> Repository {
		let url = directoryURL.URLByAppendingPathComponent(name, isDirectory: true)
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

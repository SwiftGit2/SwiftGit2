//
//  TaoTest.swift
//  SwiftGit2Tests
//
//  Created by loki on 24.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import XCTest
import Essentials

struct TaoTest {
	static let localRoot = URL(fileURLWithPath: "/tmp/tao_test", isDirectory: true)
	//let remoteURL_test_public_ssh   = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
	//let remoteURL_test_public_https = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
	
	func bla() {
		//let remoteURL = remoteURL_test_public_https
		//let localURL = localRoot.appendingPathComponent(remoteURL.lastPathComponent).deletingPathExtension()
		//localURL.rm().assertFailure("rm")
		//print("goint to clone into \(localURL)")
	}
}

struct PublicTestRepo {
	let urlSsh = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
	let urlHttps = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
	
	let localPath : URL
	
	init() {
		localPath = TaoTest.localRoot.appendingPathComponent(urlSsh.lastPathComponent).deletingPathExtension()
		localPath.rm().assertFailure("rm")
	}
}

extension Result {
	@discardableResult
	func assertFailure(_ topic: String? = nil) -> Success? {
		self.onSuccess {
			if let topic = topic {
				print("\(topic) succeeded with: \($0)")
			}
		}.onFailure {
			if let topic = topic {
				print("\(topic) failed with: \($0.fullDescription)")
			}
			XCTAssert(false)
		}
		switch self {
		case .success(let s):
			return s
		default:
			return nil
		}
	}
}

extension String {
	func write(to file: URL) -> Result<(),Error> {
		do {
			try self.write(toFile: file.path, atomically: true, encoding: .utf8)
			return .success(())
		} catch {
			return .failure(error)
		}
	}
}

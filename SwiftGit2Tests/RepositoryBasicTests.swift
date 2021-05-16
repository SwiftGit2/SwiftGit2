//
//  SwiftGit2Tests.swift
//  SwiftGit2Tests
//
//  Created by loki on 16.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import XCTest
@testable import SwiftGit2
import Essentials

class RepositoryBasicTests: XCTestCase {
    let root = URL(fileURLWithPath: "/tmp/tao_test", isDirectory: true)
    let remoteURL_test_public_ssh   = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
    let remoteURL_test_public_https = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
    let sshCredentials = Credentials.ssh(publicKey: "/Users/loki/.ssh/id_rsa.pub", privateKey: "/Users/loki/.ssh/id_rsa", passphrase: "")
    
    override func setUpWithError() throws {
        root.mkdir()
            .onSuccess { print("\($0.absoluteString) created") }
            .onFailure { print("failure: \($0)")}
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testClone() {
        let remoteURL = remoteURL_test_public_ssh
        let localURL = root.appendingPathComponent(remoteURL.lastPathComponent).deletingPathExtension()
        localURL.rm().assertFailure("rm")
        print("goint to clone into \(localURL)")
        let opt = CloneOptions(fetch: FetchOptions(credentials: sshCredentials))
        Repository.clone(from: remoteURL, to: localURL, options: opt)
            .assertFailure("clone")
    }
    
}

extension Result {
    func assertFailure(_ topic: String? = nil) {
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
    }
}

public extension URL {
    func mkdir() -> Result<URL,Error> {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return .failure(error)
        }
        
        return .success(self)
    }
    
    static var userHome : URL   { FileManager.default.homeDirectoryForCurrentUser }
    
    var exists   : Bool  { FileManager.default.fileExists(atPath: self.path) }
    
    func rm() -> Result<(),Error> {
        do {
            try FileManager.default.removeItem(atPath: self.path)
        } catch {
            return .failure(error)
        }
        
        return .success(())
    }
}


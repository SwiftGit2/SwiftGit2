//
//  RemoteRepoAccessChecker.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 20.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

// TEST CODE
public class RemoteRepoAccessChecker {
    private let tempFolder = URL(fileURLWithPath: "/tmp/TempRepo", isDirectory: true)

    public init() {}

    public func check(url: String) {
        let remoteRez = tempFolder.rm()
            .flatMap { Repository.create(at: tempFolder) }
            .flatMap { $0.createRemote(str: url) }

        let remote = try? remoteRez.get()

        print("ZZZA \(remote?.url)")
        print("ZZZA \(remote?.name)")
    }
}

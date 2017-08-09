# SwiftGit2
[![Build Status](https://travis-ci.org/SwiftGit2/SwiftGit2.svg)](https://travis-ci.org/SwiftGit2/SwiftGit2)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](#carthage)
[![GitHub release](https://img.shields.io/github/release/SwiftGit2/SwiftGit2.svg)](https://github.com/SwiftGit2/SwiftGit2/releases)
![Swift 3.0.x](https://img.shields.io/badge/Swift-3.0.x-orange.svg)

Swift bindings to [libgit2](https://github.com/libgit2/libgit2).

```swift
let URL: NSURL = ...
let repo = Repository.at(URL)
if let repo = repo.value {
    let latestCommit: Result<Commit, NSError> = repo
        .HEAD()
        .flatMap { repo.commit($0.oid) }
    if let commit = latestCommit.value {
        print("Latest Commit: \(commit.message) by \(commit.author.name)")
    } else {
        print("Could not get commit: \(latestCommit.error)")
    }
} else {
    println("Could not open repository: \(repo.error)")
}
```

## Design
SwiftGit2 uses value objects wherever possible. That means using Swift’s `struct`s and `enum`s without holding references to libgit2 objects. This has a number of advantages:

1. Values can be used concurrently.
2. Consuming values won’t result in disk access.
3. Disk access can be contained to a smaller number of APIs.

This vastly simplifies the design of long-lived applications, which are the most common use case with Swift. Consequently, SwiftGit2 APIs don’t necessarily map 1-to-1 with libgit2 APIs.

All methods for reading from or writing to a repository are on SwiftGit’s only `class`: `Repository`. This highlights the failability and mutation of these methods, while freeing up all other instances to be immutable `struct`s and `enum`s.

## Importing SwiftGit2
The easiest way to add SwiftGit2 to your project is to use [Carthage](https://github.com/Carthage/Carthage). Simply add `github "SwiftGit2/SwiftGit2"` to your `Cartfile` and run `carthage update`.

If you’d like, you can do things the ~~hard~~ old-fashioned way:

1. Add SwiftGit2 as a submodule of your project’s repository.
2. Run `git submodule update --init --recursive` to fetch all of SwiftGit2’s depedencies.
3. Add `SwiftGit2.xcodeproj` to your project’s Xcode project or workspace.
4. On the “Build Phases” tab of your application target, add `SwiftGit2.framework` to the “Link Binary With Libraries” phase. SwiftGit2 must also be added to a “Copy Frameworks” build phase.
5. **If you added SwiftGit2 to a project (not a workspace)**, you will also need to add the appropriate SwiftGit2 target to the “Target Dependencies” of your application.

## Contributions
We :heart: to receive pull requests! GitHub makes it easy:

1. Fork the repository
2. Create a branch with your changes
3. Send a Pull Request

All contributions should match GitHub’s [Swift Style Guide](https://github.com/github/swift-style-guide).

## License
SwiftGit2 is available under the MIT license.

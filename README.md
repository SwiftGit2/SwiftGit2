# SwiftGit2
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](#carthage)
[![GitHub release](https://img.shields.io/github/release/SwiftGit2/SwiftGit2.svg)](https://github.com/SwiftGit2/SwiftGit2/releases)
![Swift 5.3.x](https://img.shields.io/badge/Swift-5.3.x-orange.svg)

Swift bindings to [libgit2](https://github.com/libgit2/libgit2).

```swift
let URL: URL = ...
let result = Repository.at(URL)
switch result {
case let .success(repo):
    let latestCommit = repo
        .HEAD()
        .flatMap {
            repo.commit($0.oid)
        }

    switch latestCommit {
    case let .success(commit):
        print("Latest Commit: \(commit.message) by \(commit.author.name)")

    case let .failure(error):
        print("Could not get commit: \(error)")
    }

case let .failure(error):
    print("Could not open repository: \(error)")
}
```

## Design
SwiftGit2 uses value objects wherever possible. That means using Swift’s `struct`s and `enum`s without holding references to libgit2 objects. This has a number of advantages:

1. Values can be used concurrently.
2. Consuming values won’t result in disk access.
3. Disk access can be contained to a smaller number of APIs.

This vastly simplifies the design of long-lived applications, which are the most common use case with Swift. Consequently, SwiftGit2 APIs don’t necessarily map 1-to-1 with libgit2 APIs.

All methods for reading from or writing to a repository are on SwiftGit’s only `class`: `Repository`. This highlights the failability and mutation of these methods, while freeing up all other instances to be immutable `struct`s and `enum`s.

## Required Tools
To build SwiftGit2, you'll need the following tools installed locally:

* cmake
* libssh2
* libtool
* autoconf
* automake
* pkg-config

```
brew install cmake libssh2 libtool autoconf automake pkg-config
```

## Adding SwiftGit2 to your Project
The easiest way to add SwiftGit2 to your project is to use [Carthage](https://github.com/Carthage/Carthage). Simply add `github "SwiftGit2/SwiftGit2"` to your `Cartfile` and run `carthage update`.

If you’d like, you can do things the ~~hard~~ old-fashioned way:

1. Add SwiftGit2 as a submodule of your project’s repository.
2. Run `git submodule update --init --recursive` to fetch all of SwiftGit2’s depedencies.
3. Add `SwiftGit2.xcodeproj` to your project’s Xcode project or workspace.
4. On the “Build Phases” tab of your application target, add `SwiftGit2.framework` to the “Link Binary With Libraries” phase. SwiftGit2 must also be added to a “Copy Frameworks” build phase.
5. **If you added SwiftGit2 to a project (not a workspace)**, you will also need to add the appropriate SwiftGit2 target to the “Target Dependencies” of your application.

## Building SwiftGit2 Manually
If you want to build a copy of SwiftGit2 without Carthage, possibly for development:

1. Clone SwiftGit2
2. Run `git submodule update --init --recursive` to clone the submodules
3. Build in Xcode

## Contributions
We :heart: to receive pull requests! GitHub makes it easy:

1. Fork the repository
2. Create a branch with your changes
3. Send a Pull Request

All contributions should match GitHub’s [Swift Style Guide](https://github.com/github/swift-style-guide).

## License
SwiftGit2 is available under the MIT license.

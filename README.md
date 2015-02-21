# SwiftGit2
Swift bindings to [libgit2](https://github.com/libgit2/libgit2).

## Design
SwiftGit2 uses value objects wherever possible. That means using Swift’s `struct`s and `enum`s without holding references to libgit2 objects. This has a number of advantages:

1. Values can be used concurrently.
2. Consuming values won’t result in disk access.
3. Disk access can be contained to a smaller number of APIs.

This vastly simplifies the design of long-lived applications, which are the most common use case with Swift. Consequently, SwiftGit2 APIs don’t necessarily map 1-to-1 with libgit2 APIs.

All methods for reading from or writing to a repository are on SwiftGit’s only `class`: `Repository`. This highlights the failability and mutation of these methods, while freeing up all other instances to be immutable `struct`s and `enum`s.

## Contributions
We :heart: to receive pull requests! GitHub makes it easy:

1. Fork the repository
2. Create a branch with your changes
3. Send a Pull Request

All contributions should match GitHub’s [Swift Style Guide](https://github.com/github/swift-style-guide).

## License
SwiftGit2 is available under the MIT license.

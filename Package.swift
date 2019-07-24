// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGit2",
    platforms: [
      .macOS(.v10_11),
    ],
    products: [
        .executable(
            name: "example",
            targets: ["example"]),
        .library(
            name: "SwiftGit2",
            targets: ["SwiftGit2"]),
    ],
    dependencies: [
		.package(url: "https://github.com/Quick/Quick", from: "1.3.2"),
		.package(url: "https://github.com/Quick/Nimble", from: "7.3.1"),
		.package(url: "https://github.com/muizidn/ZipArchive", .branch("master")),
    ],
    targets: [
        .target(
            name: "example",
            dependencies: ["SwiftGit2"],
            path: "example"),
        .target(
            name: "SwiftGit2",
            dependencies: ["Clibgit2"],
			path: "SwiftGit2",
            sources: ["Swift"]),
        .target(
            name: "Clibgit2",
            path: "Clibgit2"),
        .testTarget(
			name: "SwiftGit2Tests",
			dependencies: ["SwiftGit2", "Quick", "Nimble", "ZipArchive"],
			path: "SwiftGit2Tests"),
    ]
)

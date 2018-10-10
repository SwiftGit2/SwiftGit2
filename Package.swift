// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGit2",
    products: [
        .library(
            name: "SwiftGit2",
            targets: ["SwiftGit2"]),
    ],
    dependencies: [
		.package(url: "https://github.com/antitypical/Result.git", "3.0.0" ..< "4.0.0"),
		.package(url: "https://github.com/fmccann/Clibgit2", .branch("master")),
		.package(url: "https://github.com/Quick/Quick", from: "1.3.2"),
		.package(url: "https://github.com/Quick/Nimble", from: "7.3.1"),
		.package(url: "https://github.com/weichsel/ZIPFoundation", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
            name: "SwiftGit2",
            dependencies: ["Result"],
	    	path: "SwiftGit2"),
		.testTarget(
			name: "SwiftGit2Tests",
			dependencies: ["SwiftGit2", "Quick", "Nimble", "ZIPFoundation"],
			path: "SwiftGit2Tests")
    ]
)


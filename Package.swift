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
	  	.package(url: "git@github.com:stonehouse/Clibgit2.git", .exact("1.0.0"))
    ],
    targets: [
        .target(
            name: "SwiftGit2",
            dependencies: ["Result"],
	    	path: "SwiftGit2"),
    ]
)


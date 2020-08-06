// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftGit2",
	platforms: [
		.macOS(.v10_11),
		.iOS("9.2")
	],
	products: [
		.library(
			name: "SwiftGit2",
			targets: ["SwiftGit2"]),
	],
	dependencies: [
		.package(url: "https://github.com/Quick/Quick", from: "2.2.0"),
		.package(url: "https://github.com/Quick/Nimble", from: "8.0.8"),
		.package(url: "https://github.com/marmelroy/Zip.git", from: "2.0.0"),
	],
	targets: [
		.target(
			name: "SwiftGit2",
			dependencies: ["Clibgit2"],
			path: "SwiftGit2",
			exclude: ["Info.plist"]
		),
		.binaryTarget(
			name: "Clibgit2",
			path: "External/Clibgit2.xcframework"
		),
		.testTarget(
			name: "SwiftGit2Tests",
			dependencies: ["SwiftGit2", "Quick", "Nimble", "Zip"],
			path: "SwiftGit2Tests",
			exclude: ["Info.plist"],
			resources: [
				.copy("Fixtures/repository-with-status.zip"),
				.copy("Fixtures/Mantle.zip"),
				.copy("Fixtures/simple-repository.zip"),
				.copy("Fixtures/detached-head.zip"),
			]
		),
	]
)

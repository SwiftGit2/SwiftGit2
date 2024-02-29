// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SwiftGit2",
    products: [
        .library(
            name: "SwiftGit2",
            targets: ["SwiftGit2"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/mbernson/libgit2.git", branch: "spm"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.5.5"),
    ],
    targets: [
        .target(
            name: "SwiftGit2",
            dependencies: ["libgit2"]
        ),
        .testTarget(
            name: "SwiftGit2Tests",
            dependencies: ["SwiftGit2", "libgit2", "Quick", "Nimble", "ZipArchive"],
            resources: [.copy("Fixtures")]
        ),
    ]
)

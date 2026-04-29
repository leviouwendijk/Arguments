// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Arguments",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Arguments",
            targets: ["Arguments"]
        ),

        .executable(
            name: "argtest",
            targets: ["ArgumentTestFlows"]
        ),
    ],

    dependencies: [
        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Arguments"
        ),
        .executableTarget(
            name: "ArgumentTestFlows",
            dependencies: [
                "Arguments",
                .product(name: "TestFlows", package: "TestFlows"),
            ]
        ),
        // .testTarget(
        //     name: "ArgumentsTests",
        //     dependencies: ["Arguments"]
        // ),
    ]
)

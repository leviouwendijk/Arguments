// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArgumentsTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "argtest",
            targets: ["ArgumentTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "ArgumentTestFlows",
            dependencies: [
                .product(name: "Arguments", package: "Arguments"),
                .product(name: "Testing", package: "Testing"),
            ]
        ),
        // .testTarget(
        //     name: "ArgumentsTests",
        //     dependencies: ["Arguments"]
        // ),
    ]
)

for target in package.targets {
    switch target.type {
    case .regular, .executable, .test, .macro:
        var settings = target.swiftSettings ?? []

        settings.append(
            .treatAllWarnings(as: .error)
        )

        settings.append(
            .unsafeFlags(
                [
                    "-continue-building-after-errors"
                ]
            )
        )

        target.swiftSettings = settings

    case .plugin, .system, .binary:
        break

    @unknown default:
        break
    }
}

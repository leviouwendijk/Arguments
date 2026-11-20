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
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Arguments"
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

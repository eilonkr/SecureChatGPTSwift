// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SecureChatGPTSwift",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SecureChatGPTSwift",
            targets: ["SecureChatGPTSwift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/eilonkr/ChatGPTSwift.git", branch: "main"),
        .package(url: "https://github.com/datatheorem/TrustKit.git", exact: "3.0.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SecureChatGPTSwift",
            dependencies: [
                .product(name: "ChatGPTSwift", package: "ChatGPTSwift"),
                .product(name: "TrustKit", package: "TrustKit")
            ]
        ),
        .executableTarget(
            name: "KeyEncryption"
        ),
        .testTarget(
            name: "SecureChatGPTSwiftTests",
            dependencies: ["SecureChatGPTSwift"]),
    ]
)

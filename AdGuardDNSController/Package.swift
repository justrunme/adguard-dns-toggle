// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdGuardDNSController",
    platforms: [.macOS(.v11)], // Specify macOS 11 or later
    products: [
        .executable(name: "AdGuardDNSController", targets: ["AdGuardDNSController"])
    ],
    targets: [
        .executableTarget(
            name: "AdGuardDNSController",
            path: "Sources",
            resources: [.process("../Resources")] // Include Resources folder
        ),
        .testTarget(
            name: "AdGuardDNSControllerTests",
            dependencies: ["AdGuardDNSController"],
            path: "Tests"
        )
    ]
)

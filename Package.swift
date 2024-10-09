// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Creamy3D",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(
            name: "Creamy3D",
            targets: ["Creamy3D"]),
    ],
    targets: [
        .target(
            name: "Creamy3D",
            resources: [.process("Shaders/")]
        ),
        .testTarget(
            name: "Creamy3DTests",
            dependencies: ["Creamy3D"]),
    ]
)

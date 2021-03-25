// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Quilt",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Quilt",
            targets: ["Quilt"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Quilt",
            dependencies: []),
        .testTarget(
            name: "QuiltTests",
            dependencies: ["Quilt"]),
    ]
)

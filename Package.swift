// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftQR",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftQR",
            targets: ["SwiftQR"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftQR",
            dependencies: [
                .byName(name: "Cqr")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "Cqr",
            dependencies: [],
            exclude: [
                "./c/Readme.markdown",
                "./c/Makefile",
                "./c/qrcodegen-demo.c",
                "./c/qrcodegen-test.c",
            ],
            sources: [
                "./c"
            ], 
            publicHeadersPath: "./c",
            cSettings: [
                .headerSearchPath("./c")
            ]
        ),
        .testTarget(
            name: "SwiftQRTests",
            dependencies: ["SwiftQR"]),
    ]
)

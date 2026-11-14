// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NucleantLayouts",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NucleantLayouts",
            targets: ["NucleantLayouts"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/NucleantUI/NucleantUI", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NucleantLayouts",
            dependencies: [
                .product(name: "NucleantUI", package: "NucleantUI")
            ]
        ),
        // The showcase app: every layout in the package, switched between
        // live. `swift run LayoutGallery`.
        .executableTarget(
            name: "LayoutGallery",
            dependencies: [
                "NucleantLayouts",
                .product(name: "NucleantUI", package: "NucleantUI")
            ]
        ),
        .testTarget(
            name: "NucleantLayoutsTests",
            dependencies: ["NucleantLayouts"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

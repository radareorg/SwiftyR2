// swift-tools-version: 5.9
import PackageDescription

#if canImport(Darwin)
let radare2Target: Target = .binaryTarget(
    name: "Radare2",
    url: "https://github.com/radareorg/SwiftyR2/releases/download/20260911-b015691/Radare2-20260911-b015691.xcframework.zip",
    checksum: "8fc923a9bcb4829248cc587f6463f71c80a48ef8a5c7a7667ff62d96f9dff7ca"
)
#else
let radare2Target: Target = .systemLibrary(
    name: "Radare2",
    pkgConfig: "r_core",
    providers: [
        .apt(["libradare2-dev"]),
        .brew(["radare2"]),
    ]
)
#endif

let package = Package(
    name: "SwiftyR2",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SwiftyR2",
            targets: ["SwiftyR2"]
        )
    ],
    targets: [
        radare2Target,

        .target(
            name: "SwiftyR2",
            dependencies: ["Radare2"]
        ),

        .testTarget(
            name: "SwiftyR2Tests",
            dependencies: ["SwiftyR2"]
        ),
    ]
)

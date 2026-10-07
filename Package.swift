// swift-tools-version: 5.9
import PackageDescription

#if canImport(Darwin)
let radare2Target: Target = .binaryTarget(
    name: "Radare2",
    url: "https://github.com/radareorg/SwiftyR2/releases/download/20261007-0b48eab/Radare2-20261007-0b48eab.xcframework.zip",
    checksum: "6cb08a3a6e007ce6ca7197e116bd9752da361be59b1b70d5b6e569cc3ab4bd08"
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

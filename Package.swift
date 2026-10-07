// swift-tools-version: 5.9
import PackageDescription

#if canImport(Darwin)
let radare2Target: Target = .binaryTarget(
    name: "Radare2",
    url: "https://github.com/radareorg/SwiftyR2/releases/download/20261007-2614bff/Radare2-20261007-2614bff.xcframework.zip",
    checksum: "6317b3c1051d8425558c8053a22c943611c9523f6548613317b23b0758d77e26"
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

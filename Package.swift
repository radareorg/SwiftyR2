// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftyR2",
    platforms: [
        .macOS(.v11),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "SwiftyR2",
            targets: ["SwiftyR2"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "Radare2",
            url: "https://build.frida.re/Radare2.xcframework.zip",
            checksum: "c0ddcf1e7e86cb8026b118328358d42115fbb79140da3a940cab26a91c30d92c"
        ),

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

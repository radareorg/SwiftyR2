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
            checksum: "c7c44730d3bdad75d8787c8f166d412437c057e5da9c4600132e6850412d11ca"
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

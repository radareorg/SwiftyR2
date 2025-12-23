// swift-tools-version: 5.9
import PackageDescription

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
        .binaryTarget(
            name: "Radare2",
            url: "https://build.frida.re/Radare2.xcframework.zip",
            checksum: "0ed55e0cd8879c3e0ade2f9c0b912b2db1bf40a603705cdf08c3da3346fb14e8"
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

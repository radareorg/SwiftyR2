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
            checksum: "058d580eabbe5cc26cf5618e20660ea65ecdb1148f1ce924b6b8c47974de72d9"
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

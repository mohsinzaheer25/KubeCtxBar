// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "KubeCtxBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "KubeCtxBar", targets: ["KubeCtxBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "KubeCtxBar",
            dependencies: ["Yams"],
            path: "KubeCtxBar"
        ),
        .testTarget(
            name: "KubeCtxBarTests",
            dependencies: ["KubeCtxBar"],
            path: "KubeCtxBarTests"
        )
    ]
)

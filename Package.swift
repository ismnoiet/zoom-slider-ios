// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ZoomSlider",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "ZoomSlider", targets: ["ZoomSlider"]),
        .library(name: "ZoomSliderDemo", targets: ["ZoomSliderDemo"]),
    ],
    targets: [
        .target(
            name: "ZoomSlider",
            path: "Sources/ZoomSlider"
        ),
        .target(
            name: "ZoomSliderDemo",
            dependencies: ["ZoomSlider"],
            path: "Sources/ZoomSliderDemo"
        ),
        .testTarget(
            name: "ZoomSliderTests",
            dependencies: ["ZoomSlider"],
            path: "Tests/ZoomSliderTests"
        ),
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlyphKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "GlyphKit", targets: ["GlyphKit"])
    ],
    targets: [
        .target(name: "GlyphKit"),
        .testTarget(name: "GlyphKitTests", dependencies: ["GlyphKit"])
    ],
    swiftLanguageModes: [.v6]
)

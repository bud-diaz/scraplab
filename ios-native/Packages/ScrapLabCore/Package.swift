// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScrapLabCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ScrapLabModels", targets: ["ScrapLabModels"]),
        .library(name: "ScrapLabAPI", targets: ["ScrapLabAPI"]),
    ],
    targets: [
        .target(name: "ScrapLabModels"),
        .target(name: "ScrapLabAPI", dependencies: ["ScrapLabModels"]),
        .testTarget(name: "ScrapLabModelsTests", dependencies: ["ScrapLabModels"]),
        .testTarget(name: "ScrapLabAPITests", dependencies: ["ScrapLabAPI", "ScrapLabModels"]),
    ],
    swiftLanguageModes: [.v6]
)

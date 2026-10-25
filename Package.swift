// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SpaceName",
  platforms: [.macOS(.v15)],
  targets: [
    .target(name: "SpaceNameCore"),
    .target(name: "SpaceNameSystem", dependencies: ["SpaceNameCore"]),
    .executableTarget(name: "SpaceName", dependencies: ["SpaceNameCore", "SpaceNameSystem"]),
    .testTarget(name: "SpaceNameCoreTests", dependencies: ["SpaceNameCore"]),
    .testTarget(name: "SpaceNameSystemTests", dependencies: ["SpaceNameSystem"]),
  ],
  swiftLanguageModes: [.v5]
)

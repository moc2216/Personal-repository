// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "RimeWubiAssistant",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "RimeWubiCore", targets: ["RimeWubiCore"]),
    .executable(name: "RimeWubiAssistant", targets: ["RimeWubiAssistant"]),
  ],
  targets: [
    .target(name: "RimeWubiCore", resources: [.copy("Resources/wubi86.tsv")]),
    .executableTarget(
      name: "RimeWubiAssistant",
      dependencies: ["RimeWubiCore"]
    ),
    .testTarget(
      name: "RimeWubiAssistantTests", dependencies: ["RimeWubiAssistant", "RimeWubiCore"]),
    .testTarget(
      name: "RimeWubiCoreTests",
      dependencies: ["RimeWubiCore"]
    ),
  ]
)

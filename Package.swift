// swift-tools-version: 5.9
import PackageDescription
import Foundation

let package = Package(
    name: "TimeAtlasTools",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TimeAtlas", targets: ["TimeAtlas"]),
        .executable(name: "timeatlas", targets: ["TimeAtlasCLI"]),
        .executable(name: "timeatlas-checks", targets: ["TimeAtlasChecks"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.31.0")
    ],
    targets: [
        .systemLibrary(name: "CSQLite", pkgConfig: "sqlite3"),
        .target(name: "TimeAtlas", dependencies: ["CSQLite", .product(name: "SwiftProtobuf", package: "swift-protobuf")], resources: [.process("Resources")]),
        .executableTarget(name: "TimeAtlasCLI", dependencies: ["TimeAtlas"], exclude: ["Info.plist"], linkerSettings: [.unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Sources/TimeAtlasCLI/Info.plist").path])]),
        .executableTarget(name: "TimeAtlasChecks", dependencies: ["TimeAtlas"], path: "Tests/TimeAtlasChecks")
    ]
)

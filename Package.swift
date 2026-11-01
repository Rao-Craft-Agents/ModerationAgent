// swift-tools-version:6.0
// ModerationAgent: on-device content safety for a social app — a keyword filter, an image-safety gate on a Core ML
// model the app provides, a policy and a moderator, a censor overlay and a keyword editor — written as a local Swift
// package the app links, as a Granite agent package. An app that links it finds the `moderation` agent through
// Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "ModerationAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ModerationAgent", targets: ["ModerationAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "ModerationAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "ModerationAgentTests",
            dependencies: ["ModerationAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)

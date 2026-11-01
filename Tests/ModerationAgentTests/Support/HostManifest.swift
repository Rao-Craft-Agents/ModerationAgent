import Foundation

/// Swift packages a moderation package is linked into.
enum HostManifest {
    /// A recipe app built as a package: an older macOS, a dependency already, one library, one tool and their tests.
    static let recipes = """
        // swift-tools-version:6.0
        import PackageDescription

        let package = Package(
            name: "Recipes",
            platforms: [.macOS(.v13)],
            products: [
                .library(name: "RecipeCore", targets: ["RecipeCore"]),
            ],
            dependencies: [
                .package(path: "Packages/RecipeKit"),
            ],
            targets: [
                .target(
                    name: "RecipeCore",
                    dependencies: [.product(name: "RecipeKit", package: "RecipeKit")]),
                .executableTarget(
                    name: "Check",
                    path: "Sources/Check"),
                .testTarget(
                    name: "RecipeCoreTests",
                    dependencies: ["RecipeCore"]),
            ]
        )

        """

    /// A package written on one line a list, with no platforms and no dependencies.
    static let terse = """
        // swift-tools-version:6.0
        import PackageDescription

        let package = Package(name: "Tool", targets: [.executableTarget(name: "Tool")])

        """
}

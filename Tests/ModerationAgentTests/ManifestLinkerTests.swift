import Foundation
import XCTest
@testable import ModerationAgent

/// The manifest edit: the dependency, the product on every target that builds code, the platforms, in the layout
/// the manifest already has, and nothing twice.
final class ManifestLinkerTests: XCTestCase {
    private let linker = ManifestLinker(product: "ModerationKit", packagePath: "Packages/ModerationKit", identity: "ModerationKit")

    func testARecipeManifestGetsTheDependencyTheProductAndItsPlatforms() throws {
        let outcome = linker.link(HostManifest.recipes)
        XCTAssertEqual(outcome.problems, [])
        XCTAssertEqual(outcome.targets, ["RecipeCore", "Check"])
        let text = try XCTUnwrap(outcome.text)
        XCTAssertEqual(text, """
            // swift-tools-version:6.0
            import PackageDescription

            let package = Package(
                name: "Recipes",
                platforms: [.macOS(.v14), .iOS(.v17)],
                products: [
                    .library(name: "RecipeCore", targets: ["RecipeCore"]),
                ],
                dependencies: [
                    .package(path: "Packages/RecipeKit"),
                    .package(path: "Packages/ModerationKit"),
                ],
                targets: [
                    .target(
                        name: "RecipeCore",
                        dependencies: [.product(name: "RecipeKit", package: "RecipeKit"), .product(name: "ModerationKit", package: "ModerationKit")]),
                    .executableTarget(
                        name: "Check",
                        dependencies: [.product(name: "ModerationKit", package: "ModerationKit")],
                        path: "Sources/Check"),
                    .testTarget(
                        name: "RecipeCoreTests",
                        dependencies: ["RecipeCore"]),
                ]
            )

            """)
        XCTAssertEqual(outcome.notes, ["Package.swift's macOS platform was raised from 13 to 14, the lowest the package builds for.",
                                       "Package.swift now names .iOS(.v17) among its platforms, the lowest the package builds for."])
        XCTAssertNil(linker.link(text).text, "a second link changes nothing")
    }

    func testATerseManifestKeepsItsLayout() throws {
        let text = try XCTUnwrap(linker.link(HostManifest.terse).text)
        XCTAssertTrue(text.contains(#"let package = Package(name: "Tool", platforms: [.iOS(.v17), .macOS(.v14)], dependencies: [.package(path: "Packages/ModerationKit")], targets: [.executableTarget(name: "Tool", dependencies: [.product(name: "ModerationKit", package: "ModerationKit")])])"#), text)
        XCTAssertNil(linker.link(text).text)
    }

    func testTheEditedManifestsParse() throws {
        let folder = try Fixture.folder()
        var files: [URL] = []
        for (index, manifest) in [HostManifest.recipes, HostManifest.terse].enumerated() {
            let url = folder.appendingPathComponent("Package\(index).swift")
            try XCTUnwrap(linker.link(manifest).text).write(to: url, atomically: true, encoding: .utf8)
            files.append(url)
        }
        XCTAssertNil(try SwiftParse.check(files))
    }

    func testATargetNamedLikeTheProductIsAProblem() {
        let manifest = HostManifest.terse.replacingOccurrences(of: #"name: "Tool")"#, with: #"name: "ModerationKit")"#)
        XCTAssertEqual(linker.link(manifest).problems, ["the package in the project's folder already has a target named ModerationKit: give `name` another name, like SafetyKit"])
    }

    func testAManifestItCannotReadIsNotGuessedAt() {
        let outcome = linker.link("import PackageDescription\nlet package = makePackage()\n")
        XCTAssertNil(outcome.text)
        XCTAssertEqual(outcome.notes.count, 1)
        XCTAssertTrue(outcome.notes[0].contains(#"Add `.package(path: "Packages/ModerationKit")`"#), outcome.notes[0])
    }

    func testStringsAndCommentsAreNotCode() throws {
        let manifest = """
            // swift-tools-version:6.0
            import PackageDescription
            // Package(name: "Commented", targets: [])
            let note = "Package(name: \\"Quoted\\", targets: [])"
            let package = Package(
                name: "Real", /* targets: [] */
                targets: [
                    .target(name: "Real"), // a target, at last
                ]
            )
            """
        let text = try XCTUnwrap(linker.link(manifest).text)
        XCTAssertTrue(text.contains(#".target(name: "Real", dependencies: [.product(name: "ModerationKit", package: "ModerationKit")]), // a target, at last"#), text)
        XCTAssertTrue(text.contains("// Package(name: \"Commented\", targets: [])"))
    }
}

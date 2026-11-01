import Foundation
import XCTest
@testable import ModerationAgent

/// What the package's files say: each set of parts, the call's values in them, and nothing written for a call refused.
final class KitEmitTests: XCTestCase {
    private func text(_ result: ModerationResult, _ suffix: String) throws -> String {
        let path = try XCTUnwrap(result.paths.first { $0.hasSuffix(suffix) }, "\(suffix) is written")
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    func testEverySetOfPartsRendersAndParses() throws {
        for features in Fixture.featureSets {
            let folder = try Fixture.folder()
            // The write parses every Swift file with the compiler's parser before anything lands.
            let result = try Fixture.write(.init(keywords: Fixture.starterTerms, modelURL: "https://models.example.com/food.mlmodel",
                                                 features: Array(features)), in: folder)
            XCTAssertEqual(result.features, ModerationFeature.allCases.filter(features.contains).map(\.rawValue))
            for path in result.paths {
                let text = try String(contentsOfFile: path, encoding: .utf8)
                XCTAssertFalse(text.contains("{{"), "\(path) holds a template tag")
                XCTAssertFalse(text.contains("TODO") || text.contains("fatalError"), path)
            }
            let names = Set(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent })
            XCTAssertEqual(names.contains("KeywordFilter.swift"), features.contains(.keywords), "\(features)")
            XCTAssertEqual(names.contains("CoreMLImageSafety.swift"), features.contains(.images), "\(features)")
            XCTAssertEqual(names.contains("CensorOverlay.swift"), features.contains(.overlay), "\(features)")
            XCTAssertEqual(names.contains("KeywordListEditor.swift"), features.contains(.editor), "\(features)")
            XCTAssertTrue(names.isSuperset(of: ["Package.swift", "Moderator.swift", "ModerationPolicy.swift", "Verdict.swift", "ModeratorTests.swift"]))
        }
    }

    func testTheCallsValuesLandInTheFiles() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(.init(name: "RecipeSafety", keywords: Fixture.starterTerms, label: "unsafe", threshold: 0.7,
                                             modelURL: "https://models.example.com/food-photo-safety.mlmodel", link: false), in: folder)
        XCTAssertEqual(result.folder, "Packages/RecipeSafety")
        let manifest = try text(result, "/Package.swift")
        XCTAssertTrue(manifest.contains(#".library(name: "RecipeSafety", targets: ["RecipeSafety"])"#))
        XCTAssertTrue(manifest.contains("platforms: [.iOS(.v17), .macOS(.v14)]"))
        XCTAssertTrue(manifest.contains(".swiftLanguageMode(.v6)"))
        XCTAssertFalse(manifest.contains("dependencies: [."), "the package depends on nothing")
        let policy = try text(result, "/ModerationPolicy.swift")
        XCTAssertTrue(policy.contains("blurThreshold: Double = 0.7,"))
        XCTAssertTrue(policy.contains("""
                public static let starterTerms: [String] = [
                    "spoiler", "store-bought", "crypto*",
                ]
            """))
        let gate = try text(result, "/CoreMLImageSafety.swift")
        XCTAssertTrue(gate.contains(#"public init(source: Source, unsafeLabel: String = "unsafe", folder: URL? = nil)"#))
        XCTAssertTrue(gate.contains(#"public static let defaultModelURL = URL(string: "https://models.example.com/food-photo-safety.mlmodel")!"#))
        XCTAssertTrue(try text(result, "/ModelStore.swift").contains(#".appendingPathComponent("RecipeSafety", isDirectory: true)"#))
        XCTAssertTrue(try text(result, "/ModerationPolicyTests.swift").contains("XCTAssertEqual(policy.blurThreshold, 0.7)"))
        XCTAssertTrue(try text(result, "/ModeratorTests.swift").hasPrefix("import XCTest\n@testable import RecipeSafety\n"))
        let readme = try text(result, "/README.md")
        XCTAssertTrue(readme.contains("# RecipeSafety"))
        XCTAssertTrue(readme.contains("https://models.example.com/food-photo-safety.mlmodel"))
        XCTAssertFalse(result.paths.contains { $0.hasSuffix(".mlmodel") || $0.hasSuffix(".mlmodelc") }, "no model ships")
    }

    func testWithNoModelURLThereIsNoDefaultModelAndNoTermsNoList() throws {
        let result = try Fixture.write(.init(link: false), in: try Fixture.folder())
        XCTAssertFalse(try text(result, "/CoreMLImageSafety.swift").contains("defaultModelURL"))
        XCTAssertTrue(try text(result, "/ModerationPolicy.swift").contains("public static let starterTerms: [String] = []"))
        XCTAssertTrue(try text(result, "/CoreMLImageSafety.swift").contains(#"unsafeLabel: String = "NSFW""#))
        XCTAssertTrue(try text(result, "/ModerationPolicy.swift").contains("blurThreshold: Double = 0.8,"))
    }

    func testATextOnlyPackageHoldsNoImageCode() throws {
        let result = try Fixture.write(.init(features: [.keywords], link: false), in: try Fixture.folder())
        XCTAssertFalse(result.paths.contains { $0.contains("/Images/") || $0.contains("Support/") })
        let moderator = try text(result, "/Moderator.swift")
        XCTAssertTrue(moderator.contains("public func judge(_ content: ModeratedContent) -> Verdict {"))
        XCTAssertFalse(moderator.contains("ImageSafety"))
        XCTAssertFalse(try text(result, "/ModeratedContent.swift").contains("images"))
        XCTAssertFalse(try text(result, "/ModerationPolicy.swift").contains("Threshold"))
        XCTAssertFalse(try text(result, "/README.md").contains("## Images"))
    }

    func testAnImagesOnlyPackageHoldsNoKeywordCode() throws {
        let result = try Fixture.write(.init(features: [.images, .overlay], link: false), in: try Fixture.folder())
        XCTAssertFalse(result.paths.contains { $0.contains("/Keywords/") || $0.hasSuffix("KeywordFilterTests.swift") })
        XCTAssertFalse(try text(result, "/ModerationPolicy.swift").contains("keyword"))
        XCTAssertFalse(try text(result, "/ModerationReason.swift").contains("keyword"))
        XCTAssertFalse(try text(result, "/Moderator.swift").contains("scopes"))
        XCTAssertTrue(try text(result, "/Moderator.swift").contains("public func judge(_ content: ModeratedContent) async -> Verdict {"))
    }

    func testTheEditorBringsKeywords() throws {
        let result = try Fixture.write(.init(features: [.images, .editor], link: false), in: try Fixture.folder())
        XCTAssertEqual(result.features, ["keywords", "images", "editor"])
        XCTAssertTrue(result.notes.contains("The keyword editor edits the keyword list, so keywords were added to the features."))
    }

    func testCallingAgainWithFewerPartsRemovesWhatItLeavesOut() throws {
        let folder = try Fixture.folder()
        _ = try Fixture.write(.init(link: false), in: folder)
        let again = try Fixture.write(.init(features: [.keywords], link: false), in: folder)
        XCTAssertTrue(again.removed.contains("Packages/ModerationKit/Sources/ModerationKit/Images/CoreMLImageSafety.swift"), "\(again.removed)")
        XCTAssertTrue(again.removed.contains("Packages/ModerationKit/Sources/ModerationKit/Views/CensorOverlay.swift"))
        XCTAssertFalse(again.removed.contains { $0.hasSuffix("/Moderator.swift") }, "the moderator is written again, not removed")
        let kit = folder.appendingPathComponent("Packages/ModerationKit/Sources/ModerationKit")
        XCTAssertFalse(FileManager.default.fileExists(atPath: kit.appendingPathComponent("Images").path), "an emptied folder goes too")
        XCTAssertTrue(FileManager.default.fileExists(atPath: kit.appendingPathComponent("Moderation/Moderator.swift").path))
        XCTAssertFalse(try String(contentsOf: kit.appendingPathComponent("Moderation/Moderator.swift"), encoding: .utf8).contains("ImageSafety"))
    }

    func testEveryProblemIsSaidAtOnceAndNothingIsWritten() throws {
        let folder = try Fixture.folder()
        let input = ModerationAgent.Input(name: "moderation kit", keywords: ["spoiler", "!!!"], threshold: 1.5,
                                          modelURL: "http://models.example.com/food.mlmodel", features: [.overlay])
        XCTAssertThrowsError(try Fixture.write(input, in: folder)) { error in
            guard case .refused(let reasons)? = error as? ModerationError else { return XCTFail("\(error)") }
            XCTAssertEqual(reasons.count, 5, "\(reasons)")
            let all = reasons.joined(separator: "\n")
            for part in ["`name`", "neither keywords nor images", "`!!!`", "`threshold` 1.5", "App Transport Security"] {
                XCTAssertTrue(all.contains(part), "\(part) in \(all)")
            }
            XCTAssertTrue("\(error)".hasPrefix("5 things stop this call, so nothing was written"))
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [])
    }

    func testAModelURLMustNameOneModelFileOverHTTPS() throws {
        let refused = [
            "https://models.example.com/food.zip": ".zip",
            "https://models.example.com/Food.mlpackage": ".mlpackage",
            "ftp://models.example.com/food.mlmodel": "not a web address",
            "models": "not a URL",
        ]
        for (url, reason) in refused {
            XCTAssertThrowsError(try Fixture.write(.init(modelURL: url, link: false), in: try Fixture.folder()), url) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(url): \(error)")
            }
        }
    }

    func testAFolderHoldingAnotherPackageOrOtherFilesIsRefused() throws {
        let folder = try Fixture.folder()
        let kit = folder.appendingPathComponent("Packages/ModerationKit")
        try FileManager.default.createDirectory(at: kit, withIntermediateDirectories: true)
        try "// swift-tools-version:5.7\n".write(to: kit.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try Fixture.write(.init(link: false), in: folder)) { error in
            XCTAssertTrue("\(error)".contains("already holds a package this agent did not write"), "\(error)")
        }
        let other = try Fixture.folder()
        try FileManager.default.createDirectory(at: other.appendingPathComponent("Safety"), withIntermediateDirectories: true)
        try "notes".write(to: other.appendingPathComponent("Safety/notes.txt"), atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try Fixture.write(.init(into: "Safety", link: false), in: other)) { error in
            XCTAssertTrue("\(error)".contains("already holds files"), "\(error)")
        }
        XCTAssertThrowsError(try Fixture.write(.init(into: ".", link: false), in: other)) { error in
            XCTAssertTrue("\(error)".contains("the project's own folder"), "\(error)")
        }
    }

    func testAPackageNamedLikeOneOfItsTypesIsRefused() throws {
        XCTAssertThrowsError(try Fixture.write(.init(name: "Moderator", link: false), in: try Fixture.folder())) { error in
            XCTAssertTrue("\(error)".contains("Moderator is a type or module the package already uses"), "\(error)")
        }
    }

    func testRepeatedTermsAreListedOnceAndUnusedFieldsSaid() throws {
        let result = try Fixture.write(.init(keywords: ["Spoiler", "spoiler", " SPOILER ", "Crème brûlée", "creme brulee"], label: "unsafe",
                                             features: [.keywords], link: false), in: try Fixture.folder())
        XCTAssertTrue(try text(result, "/ModerationPolicy.swift").contains(#""Spoiler", "Crème brûlée","#))
        XCTAssertTrue(result.notes.contains("3 repeated keywords were listed once."), "\(result.notes)")
        XCTAssertTrue(result.notes.contains("`label` went unused: the features leave out what it is for."), "\(result.notes)")
    }

    func testAPackageInsideASynchronizedFolderIsRefused() throws {
        let folder = try Fixture.folder()
        try RecipesProject.write(into: folder)
        XCTAssertThrowsError(try Fixture.write(.init(into: "Shared/ModerationKit"), in: folder)) { error in
            XCTAssertTrue("\(error)".contains("lies in Recipes.xcodeproj's folder Shared, whose files all join the app targets"), "\(error)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared/ModerationKit").path))
        XCTAssertEqual(try String(contentsOf: folder.appendingPathComponent("Recipes.xcodeproj/project.pbxproj"), encoding: .utf8), RecipesProject.pbxproj)
    }

    func testAFolderWithNothingToLinkSaysSo() throws {
        let result = try Fixture.write(.init(), in: try Fixture.folder())
        XCTAssertEqual(result.linked, [])
        XCTAssertEqual(result.notes, ["The project's folder holds no .xcodeproj or Package.swift, so the package was not linked."])
    }
}

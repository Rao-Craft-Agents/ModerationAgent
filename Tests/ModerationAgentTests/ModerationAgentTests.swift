import Foundation
import GraniteAgents
import XCTest
@testable import ModerationAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class ModerationAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let moderation = try XCTUnwrap(GraniteRoster.discovered().package("moderation"), "the record is in this test binary")
        XCTAssertEqual(moderation.module, "ModerationAgent")
        XCTAssertEqual(moderation.summary, ModerationAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let moderation = AnyAgentPackage(ModerationAgent.self)
        XCTAssertEqual(moderation.schema, .object([
            .init(name: "name", schema: .string, required: false),
            .init(name: "into", schema: .string, required: false),
            .init(name: "keywords", schema: .array(.string), required: false),
            .init(name: "label", schema: .string, required: false),
            .init(name: "threshold", schema: .number, required: false),
            .init(name: "modelURL", schema: .string, required: false),
            .init(name: "features", schema: .array(.choice(["keywords", "images", "overlay", "editor"])), required: false),
            .init(name: "link", schema: .boolean, required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(moderation.takesDirectory)
        XCTAssertEqual(moderation.lanes, 2)
        XCTAssertEqual(Set(moderation.fields.keys), ["name", "into", "keywords", "label", "threshold", "modelURL", "features", "link"],
                       "a note beside every field the model sees")
    }

    func testTheGuideTeachesEveryKindOfCall() throws {
        let guide = AnyAgentPackage(ModerationAgent.self).guide
        for phrase in ["`{}`", "keywords", "threshold", "modelURL", "label", "features", "into", "link", "`*`", "Moderator",
                       "censorOverlay", "KeywordListEditor", "No model ships"] {
            XCTAssertTrue(guide.contains(phrase), "the guide says \(phrase)")
        }
        let examples = guide.matches(of: /`(\{[^`]*\})`/).map { String($0.1) }
        XCTAssertGreaterThanOrEqual(examples.count, 5, "an example call for each kind")
        for example in examples {
            XCTAssertNoThrow(try JSONDecoder().decode(ModerationAgent.Input.self, from: Data(example.utf8)), "\(example) is a call")
        }
        XCTAssertFalse(guide.lowercased().contains("loom"), "examples come from another app than the one being built")
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming every file it wrote.
    func testACallThroughTheRosterWritesAndLinksTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        try RecipesProject.write(into: folder)
        let input = try JSONSerialization.data(withJSONObject: ["keywords": Fixture.starterTerms, "directory": folder.path])
        let answer = try await AnyAgentPackage(ModerationAgent.self).perform(input, host: AgentHost(directory: folder.path, ask: "keep spoilers out of the recipe feed"))
        let result = try JSONDecoder().decode(ModerationResult.self, from: answer)

        XCTAssertEqual(result.package, "ModerationKit")
        XCTAssertEqual(result.folder, "Packages/ModerationKit")
        XCTAssertEqual(result.features, ["keywords", "images", "overlay", "editor"])
        XCTAssertEqual(result.path, folder.appendingPathComponent("Packages/ModerationKit/Package.swift").path)
        XCTAssertEqual(result.linked, ["Recipes.xcodeproj (Recipes-iOS, Recipes-macOS)"])
        let kitFiles = KitCatalog.all.filter { $0.belongs(to: Set(ModerationFeature.allCases)) }.count
        XCTAssertEqual(result.paths.count, kitFiles + 1, "every file of the package, and the project")
        XCTAssertEqual(result.paths.last, folder.appendingPathComponent("Recipes.xcodeproj/project.pbxproj").path)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        XCTAssertEqual(result.removed, [])
        XCTAssertEqual(result.notes, ["The macOS deployment target of Recipes-macOS was raised from 13.0 to 14.0, the lowest the package builds for."])
        XCTAssertLessThan(answer.count, 6_000, "the answer stays small enough for a model to read")
    }

    /// A host over the wire may give its folder only in `AgentHost`: the call works there, never in the process's own.
    func testACallThatNamesNoFolderWorksInTheHostsFolder() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["features": ["keywords"]])
        let answer = try await AnyAgentPackage(ModerationAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(ModerationResult.self, from: answer)
        XCTAssertEqual(result.path, folder.appendingPathComponent("Packages/ModerationKit/Package.swift").path)
        XCTAssertFalse(result.paths.isEmpty)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path + "/"), "\(path) lies outside the host's folder")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: FileManager.default.currentDirectoryPath + "/Packages/ModerationKit/Package.swift"),
                       "nothing lands in the process's folder")
    }
}

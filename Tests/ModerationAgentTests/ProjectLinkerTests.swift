import Foundation
import XCTest
@testable import ModerationAgent

/// The project edit: what Xcode itself writes when a local package is added, read back as a plist, and nothing twice.
final class ProjectLinkerTests: XCTestCase {
    private let linker = ProjectLinker(product: "ModerationKit", packagePath: "Packages/ModerationKit")

    /// The objects that link `product` into the application target `id` of `graph`: its dependency and build file.
    private func link(of product: String, in graph: ProjectLinker.Graph, target id: String) -> (dependency: String?, built: Bool) {
        let target = graph.objects[id] ?? [:]
        let dependency = (target["packageProductDependencies"] as? [String] ?? []).first { graph.objects[$0]?["productName"] as? String == product }
        let phase = (target["buildPhases"] as? [String] ?? []).first { graph.objects[$0]?["isa"] as? String == "PBXFrameworksBuildPhase" }
        let files = phase.flatMap { graph.objects[$0]?["files"] as? [String] } ?? []
        let built = files.contains { graph.objects[$0]?["isa"] as? String == "PBXBuildFile" && graph.objects[$0]?["productRef"] as? String == dependency }
        return (dependency, built)
    }

    func testEveryAppTargetLinksTheProductBesideWhatItLinkedBefore() throws {
        let outcome = try XCTUnwrap(linker.link(RecipesProject.pbxproj, project: "Recipes.xcodeproj"))
        XCTAssertEqual(outcome.targets, ["Recipes-iOS", "Recipes-macOS"])
        let text = try XCTUnwrap(outcome.text)
        let graph = try XCTUnwrap(ProjectLinker.Graph(text), "the project still reads as a plist")

        let reference = try XCTUnwrap(graph.objects.first {
            $0.value["isa"] as? String == "XCLocalSwiftPackageReference" && $0.value["relativePath"] as? String == "Packages/ModerationKit"
        }?.key)
        XCTAssertEqual(graph.root["packageReferences"] as? [String], ["1C0000000000000000000001", reference])
        for (id, _) in graph.applicationTargets {
            let linked = link(of: "ModerationKit", in: graph, target: id)
            let dependency = try XCTUnwrap(linked.dependency)
            XCTAssertEqual(graph.objects[dependency]?["package"] as? String, reference)
            XCTAssertTrue(linked.built, "a build file in the Frameworks phase")
            XCTAssertTrue(link(of: "RecipeKit", in: graph, target: id).built, "what it linked before stays")
            XCTAssertEqual(reference.count, 24)
        }
        XCTAssertTrue(text.contains("""
            \t\t\(reference) /* XCLocalSwiftPackageReference "ModerationKit" */ = {
            \t\t\tisa = XCLocalSwiftPackageReference;
            \t\t\trelativePath = Packages/ModerationKit;
            \t\t};
            """), "the reference is written as Xcode writes it")
        XCTAssertTrue(text.contains("MACOSX_DEPLOYMENT_TARGET = 14.0;"))
        XCTAssertFalse(text.contains("MACOSX_DEPLOYMENT_TARGET = 13.0;"))
        XCTAssertEqual(outcome.notes, ["The macOS deployment target of Recipes-macOS was raised from 13.0 to 14.0, the lowest the package builds for."])

        // Every line of the project is still there, in order, but the two deployment targets raised.
        let before = RecipesProject.pbxproj.replacingOccurrences(of: "MACOSX_DEPLOYMENT_TARGET = 13.0;", with: "MACOSX_DEPLOYMENT_TARGET = 14.0;")
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)[...]
        for line in before.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let found = lines.firstIndex(of: line) else { return XCTFail("lost: \(line)") }
            lines = lines[(found + 1)...]
        }
    }

    func testASecondLinkChangesNothing() throws {
        let first = try XCTUnwrap(linker.link(RecipesProject.pbxproj, project: "Recipes.xcodeproj")?.text)
        let second = try XCTUnwrap(linker.link(first, project: "Recipes.xcodeproj"))
        XCTAssertNil(second.text)
        XCTAssertEqual(second.targets, ["Recipes-iOS", "Recipes-macOS"])
        XCTAssertEqual(second.notes, [])
    }

    func testAClassicProjectGetsEverySectionAndListItNeeds() throws {
        let outcome = try XCTUnwrap(linker.link(ClassicProject.pbxproj, project: "Classic.xcodeproj"))
        XCTAssertEqual(outcome.targets, ["Classic"], "the unit-test target is not an app")
        let text = try XCTUnwrap(outcome.text)
        let graph = try XCTUnwrap(ProjectLinker.Graph(text))
        XCTAssertEqual((graph.root["packageReferences"] as? [String])?.count, 1)
        XCTAssertTrue(link(of: "ModerationKit", in: graph, target: "A60000000000000000000001").built)
        XCTAssertNil(graph.objects["A60000000000000000000002"]?["packageProductDependencies"], "the test target is left alone")
        let order = ["/* End XCConfigurationList section */", "/* Begin XCLocalSwiftPackageReference section */",
                     "/* End XCLocalSwiftPackageReference section */", "/* Begin XCSwiftPackageProductDependency section */"]
        let offsets = try order.map { try XCTUnwrap(text.range(of: $0)?.lowerBound, $0) }
        XCTAssertEqual(offsets, offsets.sorted(), "new sections where Xcode keeps them")
        XCTAssertTrue(text.contains("\t\t\tname = Classic;\n\t\t\tpackageProductDependencies = (\n"), "a new list among the keys in Xcode's order")
        XCTAssertTrue(text.contains("\t\t\tmainGroup = A50000000000000000000001;\n\t\t\tpackageReferences = (\n"))
        XCTAssertEqual(outcome.notes, ["The iOS deployment target of the project was raised from 16.0 to 17.0, the lowest the package builds for."])
        XCTAssertTrue(text.contains("IPHONEOS_DEPLOYMENT_TARGET = 16.0;"), "the test target's own setting is not the app's")
    }

    func testAMissingFrameworksPhaseIsMadeAfterTheSources() throws {
        let text = try XCTUnwrap(linker.link(ClassicProject.withoutFrameworksPhase, project: "Classic.xcodeproj")?.text)
        let graph = try XCTUnwrap(ProjectLinker.Graph(text))
        let phases = try XCTUnwrap(graph.objects["A60000000000000000000001"]?["buildPhases"] as? [String])
        XCTAssertEqual(phases.count, 3)
        XCTAssertEqual(phases.first, "A70000000000000000000001")
        XCTAssertEqual(graph.objects[phases[1]]?["isa"] as? String, "PBXFrameworksBuildPhase")
        XCTAssertTrue(link(of: "ModerationKit", in: graph, target: "A60000000000000000000001").built)
    }

    func testAPackageBesideTheProjectIsReachedByItsPath() throws {
        let beside = ProjectLinker(product: "ModerationKit", packagePath: "../Shared Packages/ModerationKit")
        let text = try XCTUnwrap(beside.link(ClassicProject.pbxproj, project: "Classic.xcodeproj")?.text)
        XCTAssertTrue(text.contains(#"relativePath = "../Shared Packages/ModerationKit";"#), "quoted, since it has a space")
        XCTAssertNotNil(ProjectLinker.Graph(text))
    }

    func testAProjectWithNoAppTargetIsLeftAlone() throws {
        let framework = ClassicProject.pbxproj.replacingOccurrences(of: "\"com.apple.product-type.application\"", with: "\"com.apple.product-type.framework\"")
        let outcome = try XCTUnwrap(linker.link(framework, project: "Classic.xcodeproj"))
        XCTAssertNil(outcome.text)
        XCTAssertEqual(outcome.notes, ["Classic.xcodeproj has no application target, so the package was not linked into it."])
        XCTAssertNil(linker.link("not a project", project: "Broken.xcodeproj"))
    }

    func testSynchronizedFoldersAreFound() {
        XCTAssertEqual(ProjectLinker.synchronizedFolders(RecipesProject.pbxproj), ["Shared", "iOS", "macOS"])
        XCTAssertEqual(ProjectLinker.synchronizedFolders(ClassicProject.pbxproj), [])
    }

    func testVersionsAndIDs() {
        XCTAssertTrue(ProjectLinker.version("13.0", isBelow: "14.0"))
        XCTAssertTrue(ProjectLinker.version("16.4", isBelow: "17"))
        XCTAssertFalse(ProjectLinker.version("14", isBelow: "14.0"))
        XCTAssertFalse(ProjectLinker.version("\"17.0.1\"", isBelow: "17.0"))
        let first = ObjectID.make("seed")
        XCTAssertEqual(first.count, 24)
        XCTAssertTrue(first.allSatisfy(\.isHexDigit))
        XCTAssertEqual(ObjectID.fresh("seed", avoiding: PBXText("nothing")), first, "the same object, the same id")
        XCTAssertNotEqual(ObjectID.fresh("seed", avoiding: PBXText("holds \(first)")), first, "never one the file holds")
        XCTAssertEqual(ProjectLinker.plistString("Packages/ModerationKit"), "Packages/ModerationKit")
        XCTAssertEqual(ProjectLinker.plistString("My Packages/Kit"), "\"My Packages/Kit\"")
        XCTAssertEqual(RelativePath.from(URL(fileURLWithPath: "/a/app"), to: URL(fileURLWithPath: "/a/app/Packages/Kit")), "Packages/Kit")
        XCTAssertEqual(RelativePath.from(URL(fileURLWithPath: "/a/app"), to: URL(fileURLWithPath: "/a/shared/Kit")), "../shared/Kit")
    }
}

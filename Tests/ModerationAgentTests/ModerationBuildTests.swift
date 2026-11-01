import Foundation
import XCTest
@testable import ModerationAgent

/// The package built, tested and run as an app would: its own tests pass for every kind of package, it builds for the
/// iOS simulator, an app project it is linked into builds for macOS and iOS, a package it is linked into builds, and
/// its Core ML gate scores real images with a real classifier. Gated (`MODERATION_BUILD=1`): the builds take minutes.
final class ModerationBuildTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MODERATION_BUILD"] == "1", "set MODERATION_BUILD=1 to build the output")
    }

    private func check(_ run: (status: Int32, log: String), _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(run.status, 0, "\(what) failed:\n\(Shell.tail(run.log))", file: file, line: line)
    }

    func testTheWholePackageBuildsTestsAndLinksIntoAnApp() throws {
        let app = try Fixture.folder()
        try RecipesProject.write(into: app)
        let result = try Fixture.write(.init(keywords: Fixture.starterTerms, modelURL: "https://models.example.com/food-photo-safety.mlmodel"), in: app)
        XCTAssertEqual(result.linked, ["Recipes.xcodeproj (Recipes-iOS, Recipes-macOS)"])
        let package = app.appendingPathComponent("Packages/ModerationKit")

        let tests = try Shell.run(["swift", "test", "--package-path", package.path])
        check(tests, "swift test of the package")
        XCTAssertTrue(tests.log.contains("with 0 failures"), Shell.tail(tests.log))

        let derived = app.appendingPathComponent(".derived").path
        check(try Shell.run(["xcodebuild", "-scheme", "ModerationKit", "-destination", "generic/platform=iOS Simulator",
                             "-derivedDataPath", derived, "build"], in: package), "the package's iOS simulator build")

        try RecipesProject.moderatedApp("ModerationKit").write(to: app.appendingPathComponent("Shared/App.swift"), atomically: true, encoding: .utf8)
        for (scheme, destination) in [("Recipes-macOS", "platform=macOS"), ("Recipes-iOS", "generic/platform=iOS Simulator")] {
            check(try Shell.run(["xcodebuild", "-project", app.appendingPathComponent("Recipes.xcodeproj").path, "-scheme", scheme,
                                 "-destination", destination, "-derivedDataPath", derived, "CODE_SIGNING_ALLOWED=NO", "build"]),
                  "the linked app, \(scheme)")
        }
    }

    func testEveryOtherKindOfPackagePassesItsOwnTests() throws {
        for features: [ModerationFeature] in [[.keywords, .editor], [.images, .overlay], [.keywords]] {
            let folder = try Fixture.folder()
            _ = try Fixture.write(.init(name: "SafetyKit", keywords: ["spoiler"], features: features, link: false), in: folder)
            let run = try Shell.run(["swift", "test", "--package-path", folder.appendingPathComponent("Packages/SafetyKit").path])
            check(run, "swift test of a package with \(features.map(\.rawValue))")
            XCTAssertTrue(run.log.contains("with 0 failures"), Shell.tail(run.log))
        }
    }

    /// A recipe package the moderation package is linked into, whose tool screens real images with a real classifier:
    /// downloaded (from a file URL), compiled, kept, scored, and loaded again from the cache once the source is gone.
    func testTheLinkedPackageScoresImagesWithARealModel() throws {
        let host = try Fixture.folder()
        let sources: [(String, String)] = [
            ("Package.swift", HostManifest.recipes),
            ("Packages/RecipeKit/Package.swift", RecipesProject.recipeKitManifest),
            ("Packages/RecipeKit/Sources/RecipeKit/Recipe.swift", RecipesProject.recipeKitSource),
            ("Sources/RecipeCore/RecipeCore.swift", "import ModerationKit\nimport RecipeKit\n\npublic enum RecipeCore {\n    public static let policy = ModerationPolicy.standard\n}\n"),
            ("Tests/RecipeCoreTests/RecipeCoreTests.swift", "import RecipeCore\nimport XCTest\n\nfinal class RecipeCoreTests: XCTestCase {\n    func testThePolicy() { XCTAssertTrue(RecipeCore.policy.filtersKeywords) }\n}\n"),
            ("Sources/Check/main.swift", Self.check),
        ]
        for (path, text) in sources {
            let url = host.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
        let result = try Fixture.write(.init(keywords: ["spoiler"]), in: host)
        XCTAssertEqual(result.linked, ["Package.swift (RecipeCore, Check)"])
        let model = host.appendingPathComponent("brightness.mlmodel")
        try Fixture.brightnessModel.write(to: model)

        let run = try Shell.run(["swift", "run", "--package-path", host.path, "Check", model.path, host.appendingPathComponent("Models").path])
        check(run, "the tool")
        let said = Dictionary(run.log.split(separator: "\n").compactMap { line -> (String, String)? in
            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            return parts.count == 2 ? (parts[0], parts[1]) : nil
        }, uniquingKeysWith: { _, last in last })
        XCTAssertGreaterThan(Double(said["bright"] ?? "") ?? 0, 0.9, run.log)
        XCTAssertLessThan(Double(said["dark"] ?? "") ?? 1, 0.1, run.log)
        XCTAssertEqual(said["compiled"], "1", "one compiled model kept for two images asked at once")
        XCTAssertGreaterThan(Double(said["cached"] ?? "") ?? 0, 0.9, "loaded from the cache with the source gone")
        XCTAssertEqual(said["label"], "the classifier has no label Explicit; it has NSFW, SFW")
        XCTAssertEqual(said["verdict"], "blur(ModerationKit.ModerationReason.image(index: 0, score: \(said["bright"] ?? "")))")
        XCTAssertEqual(said["keyword"], "hide(ModerationKit.ModerationReason.keyword(term: \"spoiler\", field: \"title\", text: \"Spoiler\"))")

        check(try Shell.run(["swift", "test", "--package-path", host.path]), "the recipe package's own tests")
    }

    private static let check = #"""
        import CoreGraphics
        import Foundation
        import ImageIO
        import ModerationKit

        func image(gray: CGFloat) -> CGImage {
            let context = CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.setFillColor(CGColor(gray: gray, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            return context.makeImage()!
        }

        func png(gray: CGFloat) -> Data {
            let data = NSMutableData()
            let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, image(gray: gray), nil)
            CGImageDestinationFinalize(destination)
            return data as Data
        }

        let model = URL(fileURLWithPath: CommandLine.arguments[1])
        let cache = URL(fileURLWithPath: CommandLine.arguments[2])
        let safety = CoreMLImageSafety(source: .remote(model), unsafeLabel: "nsfw", folder: cache)
        async let bright = safety.score(image(gray: 1))
        async let dark = safety.score(image(gray: 0))
        let scores = try await (bright, dark)
        print("bright \(scores.0)")
        print("dark \(scores.1)")
        print("compiled \(try FileManager.default.contentsOfDirectory(atPath: cache.path).filter { $0.hasSuffix(".mlmodelc") }.count)")

        try FileManager.default.removeItem(at: model)
        print("cached \(try await CoreMLImageSafety(source: .remote(model), folder: cache).score(image(gray: 1)))")
        do {
            _ = try await CoreMLImageSafety(source: .remote(model), unsafeLabel: "Explicit", folder: cache).score(image(gray: 1))
            print("label found")
        } catch {
            print("label \(error)")
        }

        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")]), imageSafety: safety)
        print("verdict \(await moderator.judge(ModeratedContent(id: "photo", images: [.data(png(gray: 1))])))")
        print("keyword \(await moderator.judge(ModeratedContent(id: "post", text: ["title": "Spoiler: it is butter"])))")
        """#
}

//  WHAT: The generated package's tests: the keyword filter, the policy, and the moderator with a stub image screen.
//  PIN:  EDIT THE TEMPLATE, THEN BUILD IT. `MODERATION_BUILD=1 swift test` renders every set of parts and builds
//        and tests each package for real.

import Foundation

enum TestTemplates {
    static let keywordFilter = KitTemplate("Tests/{{name}}Tests/KeywordFilterTests.swift", needs: [.keywords], text: ##"""
import XCTest
@testable import {{name}}

/// The keyword filter: whole words, any case or accents, wildcards and phrases, and the term each match names.
final class KeywordFilterTests: XCTestCase {
    func testATermMatchesWholeWordsOnly() {
        let filter = KeywordFilter(["ass", "cat"])
        XCTAssertNil(filter.firstMatch(in: "A classy concatenation of bypasses"))
        XCTAssertEqual(filter.firstMatch(in: "What a CAT!")?.text, "CAT")
        XCTAssertEqual(filter.firstMatch(in: "cat-like reflexes")?.term, "cat", "punctuation ends a word")
        XCTAssertEqual(filter.firstMatch(in: "my_cat")?.term, "cat", "an underscore ends a word")
    }

    func testCaseAccentsAndWidthDoNotMatter() {
        let filter = KeywordFilter(["café", "naive", "strasse", "spam"])
        XCTAssertEqual(filter.firstMatch(in: "Meet me at the CAFE")?.term, "café")
        XCTAssertEqual(filter.firstMatch(in: "so naïve")?.text, "naïve")
        XCTAssertEqual(filter.firstMatch(in: "Die Straße")?.term, "strasse")
        XCTAssertEqual(filter.firstMatch(in: "ＳＰＡＭ here")?.term, "spam")
    }

    func testAnApostropheInsideAWordIsDropped() {
        let filter = KeywordFilter(["dont"])
        XCTAssertNotNil(filter.firstMatch(in: "I don’t know"))
        XCTAssertNotNil(filter.firstMatch(in: "I don't know"))
        XCTAssertEqual(filter.firstMatch(in: "'dont'")?.text, "dont", "an apostrophe outside a word only ends one")
    }

    func testAStarStandsForAnyLettersInAWord() {
        let filter = KeywordFilter(["spoil*", "*coin", "*ware*", "c*t"])
        XCTAssertEqual(filter.firstMatch(in: "Spoilers ahead")?.text, "Spoilers")
        XCTAssertEqual(filter.firstMatch(in: "spoil it")?.term, "spoil*", "the star may stand for nothing")
        XCTAssertEqual(filter.firstMatch(in: "buy Bitcoin now")?.term, "*coin")
        XCTAssertEqual(filter.firstMatch(in: "free MALWARES")?.term, "*ware*")
        XCTAssertEqual(filter.firstMatch(in: "join the cult")?.term, "c*t")
        XCTAssertNil(filter.firstMatch(in: "two coats"), "c*t ends with t")
        XCTAssertNil(filter.firstMatch(in: "unspoiled"), "spoil* starts the word")
    }

    func testAPhraseMatchesItsWordsInOrder() {
        let filter = KeywordFilter(["buy now", "free * money"])
        XCTAssertEqual(filter.firstMatch(in: "Buy   NOW!")?.text, "Buy   NOW")
        XCTAssertEqual(filter.firstMatch(in: "click buy-now")?.term, "buy now")
        XCTAssertNil(filter.firstMatch(in: "buy nowhere"))
        XCTAssertNil(filter.firstMatch(in: "now buy"))
        XCTAssertEqual(filter.firstMatch(in: "get free easy money")?.text, "free easy money")
        XCTAssertNil(filter.firstMatch(in: "free money"), "a lone star is exactly one word")
    }

    func testTheLongestTermWinsAndEveryMatchIsFound() throws {
        let filter = KeywordFilter(["spoiler", "spoiler alert"])
        XCTAssertEqual(filter.firstMatch(in: "Spoiler alert: he lives")?.term, "spoiler alert")
        XCTAssertEqual(filter.matches(in: "a spoiler, then a SPOILER ALERT").map(\.term), ["spoiler", "spoiler alert"])
        let text = "a spoiler here"
        let match = try XCTUnwrap(filter.firstMatch(in: text))
        XCTAssertEqual(String(text[match.range]), "spoiler", "the range is the text's own")
    }

    func testScriptsWithoutSpacesMatchInsideARun() {
        XCTAssertEqual(KeywordFilter(["東京"]).firstMatch(in: "私は東京に住んでいます")?.text, "東京")
        XCTAssertNil(KeywordFilter(["京都"]).firstMatch(in: "私は東京に住んでいます"))
    }

    func testTermsWithNoWordAreSetAside() {
        let filter = KeywordFilter(["*", "!!!", "", "ok"])
        XCTAssertEqual(filter.terms, ["ok"])
        XCTAssertEqual(filter.ignored, ["*", "!!!", ""])
        XCTAssertNil(KeywordFilter(["*"]).firstMatch(in: "anything at all"))
    }

    func testRedactingMasksTheMatchedLetters() {
        let filter = KeywordFilter(["buy now"])
        XCTAssertEqual(filter.redacting("Buy now, friends!"), "••• •••, friends!")
        XCTAssertEqual(filter.redacting("nothing here"), "nothing here")
    }

    func testThousandsOfTermsInOnePass() {
        let terms = (0..<5_000).map { "term\($0)" } + (0..<500).map { "pre\($0)*" } + ["needle*"]
        let filter = KeywordFilter(terms)
        XCTAssertEqual(filter.terms.count, 5_501)
        let text = String(repeating: "hay in a stack of words ", count: 2_000) + "Needles"
        let started = Date()
        XCTAssertEqual(filter.firstMatch(in: text)?.term, "needle*")
        XCTAssertLessThan(Date().timeIntervalSince(started), 2, "12,000 words against 5,501 terms")
    }
}
"""##)

    static let policy = KitTemplate("Tests/{{name}}Tests/ModerationPolicyTests.swift", text: ##"""
import XCTest
@testable import {{name}}

/// The policy an app persists: it round-trips, and a field an older build never wrote decodes as its default.
final class ModerationPolicyTests: XCTestCase {
    func testThePolicyRoundTripsAsJSON() throws {
        var policy = ModerationPolicy.standard
{{#keywords}}
        policy.keywords.append(KeywordRule("round trip", isEnabled: false, fields: ["title"]))
        policy.keywordAction = .blur
{{/keywords}}
{{#images}}
        policy.hideThreshold = 0.97
{{/images}}
        policy.flags = ["nsfw": .blur, "bot": .hide]
        let data = try JSONEncoder().encode(policy)
        XCTAssertEqual(try JSONDecoder().decode(ModerationPolicy.self, from: data), policy)
    }

    func testAFieldLeftOutDecodesAsItsDefault() throws {
        let empty = try JSONDecoder().decode(ModerationPolicy.self, from: Data("{}".utf8))
        XCTAssertEqual(empty, .standard)
{{#keywords}}
        let rule = try JSONDecoder().decode(KeywordRule.self, from: Data(#"{"term":"spoiler"}"#.utf8))
        XCTAssertEqual(rule, KeywordRule("spoiler"))
        XCTAssertTrue(rule.isEnabled)
{{/keywords}}
    }

    func testTheStandardPolicy() {
        let policy = ModerationPolicy.standard
{{#keywords}}
        XCTAssertEqual(policy.keywords.map(\.term), ModerationPolicy.starterTerms)
        XCTAssertTrue(policy.filtersKeywords)
        XCTAssertEqual(policy.keywordAction, .hide)
{{/keywords}}
{{#images}}
        XCTAssertTrue(policy.screensImages)
        XCTAssertEqual(policy.blurThreshold, {{threshold}})
        XCTAssertNil(policy.hideThreshold)
{{/images}}
        XCTAssertTrue(policy.flags.isEmpty)
    }
}
"""##)

    static let moderator = KitTemplate("Tests/{{name}}Tests/ModeratorTests.swift", text: ##"""
import XCTest
@testable import {{name}}

/// The moderator: content held to a policy, the verdict's reason, and what it remembers.
final class ModeratorTests: XCTestCase {
    func testAFlagDoesWhatThePolicySays() async {
        var policy = ModerationPolicy()
        policy.flags = ["nsfw": .blur, "bot": .hide]
        let moderator = Moderator(policy: policy)
        let marked = await moderator.judge(ModeratedContent(id: "1", flags: ["nsfw"]))
        let bot = await moderator.judge(ModeratedContent(id: "2", flags: ["bot", "nsfw"]))
        let other = await moderator.judge(ModeratedContent(id: "3", flags: ["pinned"]))
        XCTAssertEqual(marked, .blur(.flag("nsfw")))
        XCTAssertEqual(bot, .hide(.flag("bot")), "a hide outranks a blur")
        XCTAssertEqual(other, .allow)
    }
{{#keywords}}

    func testContentThatTripsNothingIsAllowed() async {
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")]))
        let verdict = await moderator.judge(ModeratedContent(id: "1", text: ["title": "A quiet day", "body": "Nothing to see"]))
        XCTAssertEqual(verdict, .allow)
        XCTAssertTrue(verdict.allows)
    }

    func testAKeywordHidesAndSaysWhereItWasFound() async {
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")]))
        let verdict = await moderator.judge(ModeratedContent(id: "1", text: ["title": "Spoiler: the end", "body": "fine"]))
        XCTAssertEqual(verdict, .hide(.keyword(term: "spoiler", field: "title", text: "Spoiler")))
        XCTAssertTrue(verdict.hides)
        XCTAssertEqual(verdict.reason?.systemImage, "text.badge.xmark")
    }

    func testAKeywordBlursWhenThePolicySays() async {
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")], keywordAction: .blur))
        let verdict = await moderator.judge(ModeratedContent(id: "1", text: ["body": "a spoiler"]))
        XCTAssertEqual(verdict, .blur(.keyword(term: "spoiler", field: "body", text: "spoiler")))
    }

    func testARuleLooksOnlyInItsFields() async {
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler", fields: ["body"])]))
        let inTitle = await moderator.judge(ModeratedContent(id: "1", text: ["title": "spoiler"]))
        let inBody = await moderator.judge(ModeratedContent(id: "2", text: ["body": "spoiler"]))
        XCTAssertEqual(inTitle, .allow)
        XCTAssertEqual(inBody.reason, .keyword(term: "spoiler", field: "body", text: "spoiler"))
    }

    func testAnOffRuleOrAnOffFilterLetsTextThrough() async {
        let off = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler", isEnabled: false)]))
        let unfiltered = Moderator(policy: ModerationPolicy(filtersKeywords: false, keywords: [KeywordRule("spoiler")]))
        let content = ModeratedContent(id: "1", text: ["body": "spoiler"])
        let first = await off.judge(content)
        let second = await unfiltered.judge(content)
        XCTAssertEqual(first, .allow)
        XCTAssertEqual(second, .allow)
    }

    func testANewPolicyTakesOver() async {
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")]))
        let content = ModeratedContent(id: "1", text: ["body": "spoiler"])
        let before = await moderator.judge(content)
        await moderator.update(ModerationPolicy(keywords: []))
        let after = await moderator.judge(content)
        XCTAssertTrue(before.hides)
        XCTAssertEqual(after, .allow)
    }
{{/keywords}}
{{#images}}

    /// A policy that screens images from `blur`, hides from `hide`, and checks no keyword.
    private func imagePolicy(blur: Double = 0.8, hide: Double? = nil) -> ModerationPolicy {
        var policy = ModerationPolicy(blurThreshold: blur, hideThreshold: hide)
{{#keywords}}
        policy.keywords = []
{{/keywords}}
        return policy
    }

    func testAnImageIsBlurredFromTheThresholdAndHiddenFromTheHideThreshold() async throws {
        let safety = StubImageSafety(scores: [2: 0.9, 3: 0.5, 4: 0.99])
        let moderator = Moderator(policy: imagePolicy(blur: 0.8, hide: 0.95), imageSafety: safety)
        let unsafe = await moderator.judge(ModeratedContent(id: "1", images: [.data(try SampleImage.png(width: 3)), .data(try SampleImage.png(width: 2))]))
        let safe = await moderator.judge(ModeratedContent(id: "2", images: [.data(try SampleImage.png(width: 3))]))
        let worst = await moderator.judge(ModeratedContent(id: "3", images: [.data(try SampleImage.png(width: 4))]))
        XCTAssertEqual(unsafe, .blur(.image(index: 1, score: 0.9)))
        XCTAssertEqual(safe, .allow)
        XCTAssertEqual(worst, .hide(.image(index: 0, score: 0.99)))
    }

    func testAnImageTheAppDecodedIsScreenedAsItIs() async throws {
        let safety = StubImageSafety(scores: [700: 0.9])
        let moderator = Moderator(policy: imagePolicy(), imageSafety: safety)
        let verdict = await moderator.judge(ModeratedContent(id: "1", images: [.image(try SampleImage.image(width: 700))]))
        XCTAssertEqual(verdict, .blur(.image(index: 0, score: 0.9)), "not scaled down: the classifier scales it")
        XCTAssertEqual(verdict.reason?.systemImage, "eye.slash.fill")
    }

    func testALargeImageIsDecodedNoLargerThanTheClassifierNeeds() async throws {
        let safety = StubImageSafety(scores: [512: 0.9])
        let moderator = Moderator(policy: imagePolicy(), imageSafety: safety)
        let verdict = await moderator.judge(ModeratedContent(id: "1", images: [.data(try SampleImage.png(width: 1_400))]))
        XCTAssertEqual(verdict, .blur(.image(index: 0, score: 0.9)), "a 1,400-pixel photo is screened at 512")
    }

    func testImagesAreNotScreenedWhenThePolicySaysNot() async throws {
        let safety = StubImageSafety(scores: [2: 0.9])
        var policy = imagePolicy()
        policy.screensImages = false
        let moderator = Moderator(policy: policy, imageSafety: safety)
        let verdict = await moderator.judge(ModeratedContent(id: "1", images: [.data(try SampleImage.png(width: 2))]))
        let asked = await safety.asked
        XCTAssertEqual(verdict, .allow)
        XCTAssertEqual(asked, 0)
    }

    func testAnImageByURLIsLoadedAndItsScoreKept() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("moderation-\(UUID().uuidString).png")
        try SampleImage.png(width: 2).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let safety = StubImageSafety(scores: [2: 0.9])
        let moderator = Moderator(policy: imagePolicy(), imageSafety: safety)
        let first = await moderator.judge(ModeratedContent(id: "1", images: [.url(file)]))
        let second = await moderator.judge(ModeratedContent(id: "2", images: [.url(file)]))
        let asked = await safety.asked
        XCTAssertEqual(first, .blur(.image(index: 0, score: 0.9)))
        XCTAssertEqual(second, first)
        XCTAssertEqual(asked, 1, "the second post shows the same image: its score is kept")
    }

    func testAnImageThatCannotBeLoadedNeitherHidesNorIsRemembered() async throws {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("moderation-missing-\(UUID().uuidString).png")
        let safety = StubImageSafety(scores: [2: 0.9])
        let moderator = Moderator(policy: imagePolicy(), imageSafety: safety)
        let content = ModeratedContent(id: "1", images: [.url(missing)])
        let before = await moderator.judge(content)
        XCTAssertEqual(before, .allow)
        try SampleImage.png(width: 2).write(to: missing)
        defer { try? FileManager.default.removeItem(at: missing) }
        let after = await moderator.judge(content)
        XCTAssertEqual(after, .blur(.image(index: 0, score: 0.9)), "the next look screens the image")
    }

    func testAVerdictIsRememberedUntilTheContentOrThePolicyChanges() async throws {
        let safety = StubImageSafety(scores: [2: 0.9])
        let moderator = Moderator(policy: imagePolicy(), imageSafety: safety)
        let content = ModeratedContent(id: "1", images: [.data(try SampleImage.png(width: 2))])
        _ = await moderator.judge(content)
        _ = await moderator.judge(content)
        var asked = await safety.asked
        XCTAssertEqual(asked, 1, "judged once")

        var edited = content
        edited.flags = ["edited"]
        _ = await moderator.judge(edited)
        asked = await safety.asked
        XCTAssertEqual(asked, 2, "the same id with other content is judged again")

        await moderator.update(imagePolicy(blur: 0.95))
        let verdict = await moderator.judge(edited)
        asked = await safety.asked
        XCTAssertEqual(asked, 3, "a new policy judges again")
        XCTAssertEqual(verdict, .allow)
    }
{{#keywords}}

    func testAHideOutranksABlurWhateverFoundItFirst() async throws {
        let safety = StubImageSafety(scores: [2: 0.99])
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")], hideThreshold: 0.95, flags: ["nsfw": .blur]),
                                  imageSafety: safety)
        let verdict = await moderator.judge(ModeratedContent(id: "1", text: ["body": "fine"], images: [.data(try SampleImage.png(width: 2))], flags: ["nsfw"]))
        XCTAssertEqual(verdict, .hide(.image(index: 0, score: 0.99)))
    }
{{/keywords}}

    func testManyPiecesAtOnce() async throws {
        let safety = StubImageSafety(scores: [2: 0.9, 3: 0.1])
        var policy = imagePolicy()
        policy.flags = ["bot": .hide]
        let moderator = Moderator(policy: policy, imageSafety: safety)
        let verdicts = await moderator.judge([
            ModeratedContent(id: "a", flags: ["bot"]),
            ModeratedContent(id: "b", images: [.data(try SampleImage.png(width: 2))]),
            ModeratedContent(id: "c", images: [.data(try SampleImage.png(width: 3))]),
        ])
        XCTAssertEqual(verdicts["a"], .hide(.flag("bot")))
        XCTAssertEqual(verdicts["b"], .blur(.image(index: 0, score: 0.9)))
        XCTAssertEqual(verdicts["c"], .allow)
    }
{{/images}}
{{^images}}

    func testManyPiecesAtOnce() async {
        let moderator = Moderator(policy: ModerationPolicy(keywords: [KeywordRule("spoiler")]))
        let verdicts = await moderator.judge([
            ModeratedContent(id: "a", text: ["title": "spoiler"]),
            ModeratedContent(id: "b", text: ["title": "hello"]),
        ])
        XCTAssertEqual(verdicts["a"]?.hides, true)
        XCTAssertEqual(verdicts["b"], .allow)
    }
{{/images}}
}
"""##)

    static let stub = KitTemplate("Tests/{{name}}Tests/Support/StubImageSafety.swift", needs: [.images], text: ##"""
import CoreGraphics
@testable import {{name}}

/// An image-safety model for tests: an image's score is set by its width, and every question is counted.
actor StubImageSafety: ImageSafety {
    private let scores: [Int: Double]
    private(set) var asked = 0

    init(scores: [Int: Double]) {
        self.scores = scores
    }

    func score(_ image: CGImage) async throws -> Double {
        asked += 1
        guard let score = scores[image.width] else { throw ImageSafetyError.unreadableImage }
        return score
    }
}
"""##)

    static let sample = KitTemplate("Tests/{{name}}Tests/Support/SampleImage.swift", needs: [.images], text: ##"""
import CoreGraphics
import Foundation
import ImageIO

/// Images made in memory for tests.
enum SampleImage {
    struct Unmade: Error {}

    /// A square image `width` pixels wide, one gray all over.
    static func image(width: Int, gray: CGFloat = 0.5) throws -> CGImage {
        guard let context = CGContext(data: nil, width: width, height: width, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw Unmade() }
        context.setFillColor(CGColor(gray: gray, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: width))
        guard let image = context.makeImage() else { throw Unmade() }
        return image
    }

    /// The same image as PNG bytes.
    static func png(width: Int, gray: CGFloat = 0.5) throws -> Data {
        let image = try image(width: width, gray: gray)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { throw Unmade() }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw Unmade() }
        return data as Data
    }
}
"""##)
}

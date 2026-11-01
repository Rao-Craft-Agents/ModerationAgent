//  WHAT: The generated package's judge: the policy, the content, the reason and verdict, and the moderator actor.
//  PIN:  EDIT THE TEMPLATE, THEN BUILD IT. `MODERATION_BUILD=1 swift test` renders every set of parts and builds
//        and tests each package for real.

import Foundation

enum ModerationTemplates {
    static let action = KitTemplate("Sources/{{name}}/Moderation/ModerationAction.swift", text: ##"""
//  WHAT: What a policy does with content that trips it: blur it under its reason, or hide it.

import Foundation

/// What a policy does with content that trips it.
public enum ModerationAction: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Shown blurred, with the reason, until the person reveals it.
    case blur
    /// Left out of lists; where it must be shown, folded to a line with the reason.
    case hide

    public var id: Self { self }

    /// Its name in a picker.
    public var title: LocalizedStringResource {
        switch self {
        case .blur: "Blur"
        case .hide: "Hide"
        }
    }
}
"""##)

    static let policy = KitTemplate("Sources/{{name}}/Moderation/ModerationPolicy.swift", text: ##"""
//  WHAT: What content is held to, in one value an app persists:
{{#keywords}}
//        the keyword list, whether it is on, and what a match does;
{{/keywords}}
{{#images}}
//        whether images are screened, and the scores that blur or hide them;
{{/images}}
//        and what the source's own flags do (a post its server marked `nsfw`, an account marked `bot`).
//  PIN:  A FIELD LEFT OUT DECODES AS ITS DEFAULT. A policy saved by an older build still loads after a field is
//        added, so a person's list is never lost to an update.

import Foundation

/// What a moderator holds content to.
public struct ModerationPolicy: Codable, Sendable, Hashable {
{{#keywords}}
    /// Whether text is checked against `keywords`.
    public var filtersKeywords: Bool
    /// The words and phrases that trip the policy.
    public var keywords: [KeywordRule]
    /// What a keyword match does.
    public var keywordAction: ModerationAction
{{/keywords}}
{{#images}}
    /// Whether images are scored by the image-safety model.
    public var screensImages: Bool
    /// An image scoring this or more, from 0 to 1, is blurred.
    public var blurThreshold: Double
    /// An image scoring this or more is hidden; nil: an image is only ever blurred.
    public var hideThreshold: Double?
{{/images}}
    /// What each flag a source sets does: `["nsfw": .blur, "bot": .hide]`; a flag not listed does nothing.
    public var flags: [String: ModerationAction]

    public init(
{{#keywords}}
        filtersKeywords: Bool = true,
        keywords: [KeywordRule] = ModerationPolicy.starterTerms.map { KeywordRule($0) },
        keywordAction: ModerationAction = .hide,
{{/keywords}}
{{#images}}
        screensImages: Bool = true,
        blurThreshold: Double = {{threshold}},
        hideThreshold: Double? = nil,
{{/images}}
        flags: [String: ModerationAction] = [:]
    ) {
{{#keywords}}
        self.filtersKeywords = filtersKeywords
        self.keywords = keywords
        self.keywordAction = keywordAction
{{/keywords}}
{{#images}}
        self.screensImages = screensImages
        self.blurThreshold = blurThreshold
        self.hideThreshold = hideThreshold
{{/images}}
        self.flags = flags
    }

    /// The policy a new install starts with: every default above.
    public static let standard = ModerationPolicy()
{{#keywords}}

    /// The terms a new policy starts with.
    public static let starterTerms: [String] = {{starterTerms}}
{{/keywords}}

    private enum CodingKeys: String, CodingKey {
{{#keywords}}
        case filtersKeywords, keywords, keywordAction
{{/keywords}}
{{#images}}
        case screensImages, blurThreshold, hideThreshold
{{/images}}
        case flags
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let standard = ModerationPolicy.standard
{{#keywords}}
        filtersKeywords = try container.decodeIfPresent(Bool.self, forKey: .filtersKeywords) ?? standard.filtersKeywords
        keywords = try container.decodeIfPresent([KeywordRule].self, forKey: .keywords) ?? standard.keywords
        keywordAction = try container.decodeIfPresent(ModerationAction.self, forKey: .keywordAction) ?? standard.keywordAction
{{/keywords}}
{{#images}}
        screensImages = try container.decodeIfPresent(Bool.self, forKey: .screensImages) ?? standard.screensImages
        blurThreshold = try container.decodeIfPresent(Double.self, forKey: .blurThreshold) ?? standard.blurThreshold
        hideThreshold = try container.decodeIfPresent(Double.self, forKey: .hideThreshold) ?? standard.hideThreshold
{{/images}}
        flags = try container.decodeIfPresent([String: ModerationAction].self, forKey: .flags) ?? standard.flags
    }
}
"""##)

    static let content = KitTemplate("Sources/{{name}}/Moderation/ModeratedContent.swift", text: ##"""
//  WHAT: A piece of content to judge, as the app has it: what it is known by,
{{#keywords}}
//        its text by field,
{{/keywords}}
{{#images}}
//        its images,
{{/images}}
//        and the flags its source set.

import Foundation

/// A piece of content to judge.
public struct ModeratedContent: Sendable, Hashable, Identifiable {
{{#images}}
    /// What the content is known by: a verdict is remembered by it until the content or the policy changes.
    /// Empty: never remembered.
{{/images}}
{{^images}}
    /// What the content is known by: the key of its verdict in `Moderator.judge(_:)` of many.
{{/images}}
    public var id: String
{{#keywords}}
    /// Its text by field (`["title": …, "body": …, "author": …]`); a keyword rule may look in some fields only.
    public var text: [String: String]
{{/keywords}}
{{#images}}
    /// Its images, by URL or as data.
    public var images: [ModeratedImage]
{{/images}}
    /// What its source says of it (`nsfw`, `bot`), held to the policy's flags.
    public var flags: Set<String>

    public init(
        id: String,
{{#keywords}}
        text: [String: String] = [:],
{{/keywords}}
{{#images}}
        images: [ModeratedImage] = [],
{{/images}}
        flags: Set<String> = []
    ) {
        self.id = id
{{#keywords}}
        self.text = text
{{/keywords}}
{{#images}}
        self.images = images
{{/images}}
        self.flags = flags
    }
}
"""##)

    static let image = KitTemplate("Sources/{{name}}/Moderation/ModeratedImage.swift", needs: [.images], text: ##"""
//  WHAT: An image to screen: where it is, its bytes, or the image itself when the app has already decoded it (a
//        thumbnail it shows), so nothing is fetched or decoded twice.

import CoreGraphics
import Foundation

/// An image to screen.
public enum ModeratedImage: Sendable, Hashable {
    /// An image to load: over https, or a file.
    case url(URL)
    /// An image already loaded: PNG, JPEG, HEIC, or anything else ImageIO reads.
    case data(Data)
    /// An image already decoded (`uiImage.cgImage`, `nsImage.cgImage(forProposedRect:context:hints:)`).
    case image(CGImage)
}
"""##)

    static let reason = KitTemplate("Sources/{{name}}/Moderation/ModerationReason.swift", text: ##"""
//  WHAT: Why content was blurred or hidden:
{{#keywords}}
//        the term and the field it was found in,
{{/keywords}}
{{#images}}
//        the image and its score,
{{/images}}
//        or the flag its source set; and a few words of it for a person.

import Foundation

/// Why content was blurred or hidden.
public enum ModerationReason: Sendable, Hashable {
{{#keywords}}
    /// A term of the list was found in a text field: the term as listed, the field, and the words as written.
    case keyword(term: String, field: String, text: String)
{{/keywords}}
{{#images}}
    /// An image scored at or above a threshold: its place among the content's images, and its score.
    case image(index: Int, score: Double)
{{/images}}
    /// The source flagged the content.
    case flag(String)

    /// The reason in a few words, for a person: "Contains “spoiler”", "Sensitive image", "Marked nsfw".
    public var summary: LocalizedStringResource {
        switch self {
{{#keywords}}
        case .keyword(let term, _, _): "Contains “\(term)”"
{{/keywords}}
{{#images}}
        case .image: "Sensitive image"
{{/images}}
        case .flag(let flag): "Marked \(flag)"
        }
    }

    /// An SF Symbol for the reason, for a cover or a badge.
    public var systemImage: String {
        switch self {
{{#keywords}}
        case .keyword: "text.badge.xmark"
{{/keywords}}
{{#images}}
        case .image: "eye.slash.fill"
{{/images}}
        case .flag: "flag.fill"
        }
    }
}
"""##)

    static let verdict = KitTemplate("Sources/{{name}}/Moderation/Verdict.swift", text: ##"""
//  WHAT: What a moderator decides about a piece of content: allow it, blur it, or hide it, with the reason.

import Foundation

/// What a moderator decides about a piece of content.
public enum Verdict: Sendable, Hashable {
    /// Nothing tripped the policy.
    case allow
    /// Shown blurred, under its reason, until the person reveals it.
    case blur(ModerationReason)
    /// Left out of lists; where it must be shown, folded to a line with its reason.
    case hide(ModerationReason)

    /// Why it is blurred or hidden; nil when it is allowed.
    public var reason: ModerationReason? {
        switch self {
        case .allow: nil
        case .blur(let reason), .hide(let reason): reason
        }
    }

    /// Whether the content is shown as it is.
    public var allows: Bool { self == .allow }

    /// Whether the content is left out of lists.
    public var hides: Bool {
        if case .hide = self { return true }
        return false
    }
}
"""##)

    static let cache = KitTemplate("Sources/{{name}}/Moderation/BoundedCache.swift", needs: [.images], text: ##"""
//  WHAT: A dictionary that keeps only its newest entries: what the moderator remembers of verdicts and scores, so a
//        long scroll through a feed never grows memory without end.

import Foundation

struct BoundedCache<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    /// How many entries it keeps; the oldest goes first.
    let limit: Int
    private var values: [Key: Value] = [:]
    private var order: [Key] = []

    init(limit: Int) { self.limit = limit }

    subscript(key: Key) -> Value? {
        get { values[key] }
        set {
            guard let newValue else {
                if values.removeValue(forKey: key) != nil { order.removeAll { $0 == key } }
                return
            }
            if values.updateValue(newValue, forKey: key) == nil {
                order.append(key)
                if order.count > limit { values[order.removeFirst()] = nil }
            }
        }
    }

    mutating func removeAll() {
        values.removeAll()
        order.removeAll()
    }
}
"""##)

    static let screeningModerator = KitTemplate("Sources/{{name}}/Moderation/Moderator.swift", needs: [.images], text: ##"""
//  WHAT: The judge: a piece of content held to a policy, into a verdict with its reason. The source's flags first,
{{#keywords}}
//        then every text field against the keyword list,
{{/keywords}}
//        then every image through the image-safety model. A hide outranks a blur; the first reason of the stronger
//        kind is the one given.
//  PIN:  NEVER ON THE MAIN THREAD. The moderator is an actor: a view awaits a verdict, and the matching, the image
//        loading and the scoring happen beside it.
//  PIN:  AN IMAGE THAT CANNOT BE SCREENED DOES NOT HIDE CONTENT. When it cannot be loaded, or the model is not
//        ready (offline on a first launch), the content is judged on the rest, and that verdict is not remembered,
//        so the next look screens the image.
//  PIN:  REMEMBERED, BOUNDED. A verdict is kept by the content's id while the content and the policy stay the same,
//        and an image's score by its URL, each for the newest few hundred: a feed scrolled back up is not judged
//        again, and a long scroll never grows memory without end.

import CoreGraphics
import Foundation

/// Judges content against a policy, off the main thread.
public actor Moderator {
    /// The policy content is held to.
    public private(set) var policy: ModerationPolicy
    private let imageSafety: (any ImageSafety)?
    private let loader: ImageLoader
{{#keywords}}
    private var scopes: [KeywordScope]
{{/keywords}}
    private var verdicts = BoundedCache<String, (fingerprint: Int, verdict: Verdict)>(limit: 512)
    private var scores = BoundedCache<URL, Double>(limit: 256)
    private var running: [String: (fingerprint: Int, task: Task<Judgment, Never>)] = [:]
    /// Bumped by every new policy, so a verdict judged under an older one is not kept.
    private var generation = 0

    /// - Parameters:
    ///   - policy: what content is held to.
    ///   - imageSafety: what screens images; with none, images are not screened.
    ///   - session: what loads images by URL.
    public init(policy: ModerationPolicy = .standard, imageSafety: (any ImageSafety)? = nil, session: URLSession = .shared) {
        self.policy = policy
        self.imageSafety = imageSafety
        self.loader = ImageLoader(session: session)
{{#keywords}}
        self.scopes = KeywordScope.scopes(for: policy.keywords)
{{/keywords}}
    }

    /// Holds content to `policy` from now on; every verdict given under the old one is forgotten.
    public func update(_ policy: ModerationPolicy) {
        guard policy != self.policy else { return }
        self.policy = policy
{{#keywords}}
        scopes = KeywordScope.scopes(for: policy.keywords)
{{/keywords}}
        verdicts.removeAll()
        generation += 1
    }

    /// The verdict on `content`.
    public func judge(_ content: ModeratedContent) async -> Verdict {
        guard !content.id.isEmpty else { return await judgment(of: content).verdict }
        let fingerprint = content.hashValue
        if let known = verdicts[content.id], known.fingerprint == fingerprint { return known.verdict }
        if let pending = running[content.id], pending.fingerprint == fingerprint { return await pending.task.value.verdict }

        let generation = generation
        let task = Task { await self.judgment(of: content) }
        running[content.id] = (fingerprint, task)
        let judgment = await task.value
        if running[content.id]?.task == task { running[content.id] = nil }
        if judgment.isComplete, generation == self.generation { verdicts[content.id] = (fingerprint, judgment.verdict) }
        return judgment.verdict
    }

    /// The verdicts on many pieces of content at once, by id: their images load side by side.
    public func judge(_ contents: [ModeratedContent]) async -> [String: Verdict] {
        await withTaskGroup(of: (String, Verdict).self) { group in
            for content in contents {
                group.addTask { (content.id, await self.judge(content)) }
            }
            var verdicts: [String: Verdict] = [:]
            for await (id, verdict) in group { verdicts[id] = verdict }
            return verdicts
        }
    }

    // MARK: - Judging

    /// A verdict, and whether every image was screened.
    struct Judgment: Sendable {
        var verdict: Verdict
        var isComplete: Bool
    }

    private func judgment(of content: ModeratedContent) async -> Judgment {
        let policy = policy
        var blur: ModerationReason?

        for flag in content.flags.sorted() {
            switch policy.flags[flag] {
            case .hide?: return Judgment(verdict: .hide(.flag(flag)), isComplete: true)
            case .blur?: blur = blur ?? .flag(flag)
            case nil: break
            }
        }
{{#keywords}}

        if policy.filtersKeywords, let found = Self.keyword(in: content, scopes: scopes) {
            switch policy.keywordAction {
            case .hide: return Judgment(verdict: .hide(found), isComplete: true)
            case .blur: blur = blur ?? found
            }
        }
{{/keywords}}

        var isComplete = true
        // Without a hide threshold an image can only blur, and once a blur is decided there is no need to look.
        if policy.screensImages, let imageSafety, blur == nil || policy.hideThreshold != nil {
            for (index, image) in content.images.enumerated() {
                guard let score = await score(image, with: imageSafety) else { isComplete = false; continue }
                if let hide = policy.hideThreshold, score >= hide {
                    return Judgment(verdict: .hide(.image(index: index, score: score)), isComplete: true)
                }
                if score >= policy.blurThreshold { blur = blur ?? .image(index: index, score: score) }
            }
        }
        return Judgment(verdict: blur.map(Verdict.blur) ?? .allow, isComplete: isComplete)
    }
{{#keywords}}

    /// The first term found in `content`'s text, its fields read in name order.
    private static func keyword(in content: ModeratedContent, scopes: [KeywordScope]) -> ModerationReason? {
        for field in content.text.keys.sorted() {
            guard let text = content.text[field], !text.isEmpty else { continue }
            for scope in scopes where scope.applies(to: field) {
                if let match = scope.filter.firstMatch(in: text) {
                    return .keyword(term: match.term, field: field, text: match.text)
                }
            }
        }
        return nil
    }
{{/keywords}}

    /// `image`'s score, remembered by its URL; nil when it cannot be loaded or scored.
    private func score(_ image: ModeratedImage, with imageSafety: any ImageSafety) async -> Double? {
        if case .url(let url) = image, let known = scores[url] { return known }
        do {
            let picture = try await loader.image(image)
            let score = try await imageSafety.score(picture)
            if case .url(let url) = image { scores[url] = score }
            return score
        } catch {
            return nil
        }
    }
}
"""##)

    static let textModerator = KitTemplate("Sources/{{name}}/Moderation/Moderator.swift", lacks: [.images], text: ##"""
//  WHAT: The judge: a piece of content held to a policy, into a verdict with its reason. The source's flags first,
//        then every text field against the keyword list. A hide outranks a blur; the first reason of the stronger
//        kind is the one given.
//  PIN:  NEVER ON THE MAIN THREAD. The moderator is an actor: a view awaits a verdict, and the matching happens
//        beside it.

import Foundation

/// Judges content against a policy, off the main thread.
public actor Moderator {
    /// The policy content is held to.
    public private(set) var policy: ModerationPolicy
    private var scopes: [KeywordScope]

    /// - Parameter policy: what content is held to.
    public init(policy: ModerationPolicy = .standard) {
        self.policy = policy
        self.scopes = KeywordScope.scopes(for: policy.keywords)
    }

    /// Holds content to `policy` from now on.
    public func update(_ policy: ModerationPolicy) {
        guard policy != self.policy else { return }
        self.policy = policy
        scopes = KeywordScope.scopes(for: policy.keywords)
    }

    /// The verdict on `content`.
    public func judge(_ content: ModeratedContent) -> Verdict {
        var blur: ModerationReason?
        for flag in content.flags.sorted() {
            switch policy.flags[flag] {
            case .hide?: return .hide(.flag(flag))
            case .blur?: blur = blur ?? .flag(flag)
            case nil: break
            }
        }
        if policy.filtersKeywords, let found = keyword(in: content) {
            switch policy.keywordAction {
            case .hide: return .hide(found)
            case .blur: blur = blur ?? found
            }
        }
        return blur.map(Verdict.blur) ?? .allow
    }

    /// The verdicts on many pieces of content at once, by id.
    public func judge(_ contents: [ModeratedContent]) -> [String: Verdict] {
        var verdicts: [String: Verdict] = [:]
        for content in contents { verdicts[content.id] = judge(content) }
        return verdicts
    }

    /// The first term found in `content`'s text, its fields read in name order.
    private func keyword(in content: ModeratedContent) -> ModerationReason? {
        for field in content.text.keys.sorted() {
            guard let text = content.text[field], !text.isEmpty else { continue }
            for scope in scopes where scope.applies(to: field) {
                if let match = scope.filter.firstMatch(in: text) {
                    return .keyword(term: match.term, field: field, text: match.text)
                }
            }
        }
        return nil
    }
}
"""##)
}

//  WHAT: On-device content safety for an app that shows what people post, as a Granite agent package. A call writes
//        a local Swift package (Packages/ModerationKit unless it says otherwise): a keyword filter, an image-safety
//        gate on a Core ML model the app provides, a policy the app persists, a moderator that judges content into
//        allow, blur or hide, a censor overlay and a keyword list editor, with its tests; then links it into the
//        `.xcodeproj` or `Package.swift` in the host's folder, and answers where.
//  IN:   Input: the package's name and folder, its starter terms, the classifier's unsafe label, the blur threshold,
//        the model's download URL, the parts to write, and whether to link.
//  OUT:  ModerationResult: every file written, the parts, where it was linked, what was removed, and notes.
//  PIN:  NO MODEL IS ASKED, AND NO MODEL SHIPS. Every file comes from a template, the same way every time; the
//        image classifier is the app's to provide, by name, by path or by URL.
//  PIN:  WHOLE OR NOTHING. Every problem with a call is said at once and nothing is written; otherwise the package,
//        the project and the manifest are staged, checked and moved into place together.
//  PIN:  THE HOST'S FOLDER. A call that names no `directory` works in the host's (`context.host.directory`), then the
//        process's: a host calling over the wire may give the folder only there, and a runner's own folder is not
//        the project.

import Foundation
import GraniteAgents

public struct ModerationAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The package's name: its module, product and folder name; `ModerationKit` when left out.
        public var name: String?
        /// The package's folder, relative to the project; `Packages/<name>` when left out.
        public var into: String?
        /// The terms a new policy starts with: words, phrases, `*` for any letters (`spoiler`, `buy now`, `crypto*`).
        public var keywords: [String]?
        /// The image classifier's label that means unsafe; `NSFW` when left out.
        public var label: String?
        /// The score, from 0 to 1, from which an image is blurred; 0.8 when left out.
        public var threshold: Double?
        /// The https URL of an `.mlmodel` the app downloads on first use, compiles and keeps.
        public var modelURL: String?
        /// The parts to write; all four when left out.
        public var features: [ModerationFeature]?
        /// Whether to link the package into the project or package in the host's folder; true when left out.
        public var link: Bool?
        /// The host's folder.
        public var directory: String?

        public init(name: String? = nil, into: String? = nil, keywords: [String]? = nil, label: String? = nil, threshold: Double? = nil,
                    modelURL: String? = nil, features: [ModerationFeature]? = nil, link: Bool? = nil, directory: String? = nil) {
            self.name = name; self.into = into; self.keywords = keywords; self.label = label; self.threshold = threshold
            self.modelURL = modelURL; self.features = features; self.link = link; self.directory = directory
        }
    }

    public typealias Event = ModerationFrame
    public typealias Output = ModerationResult
    public typealias Compute = Void

    public static let word = "moderation"
    public static let summary = "writes an app's on-device content safety as a local Swift package — a keyword filter, an image-safety gate on a Core ML model the app provides, a policy, a moderator, a censor overlay and a keyword editor — and links it into the app."
    public static let fields = [
        "name": "the package's name, which is also its module, product and folder name; ModerationKit when left out",
        "into": "the package's folder, relative to the project; Packages/<name> when left out, and never inside a folder whose files join the app targets",
        "keywords": "the terms a new install filters, one word or phrase an item, matched as whole words in any case or accents, `*` for any letters: `spoiler`, `buy now`, `crypto*`",
        "label": "the image classifier's label that means unsafe, whose confidence is an image's score; NSFW when left out",
        "threshold": "the score from 0 to 1 from which an image is blurred; 0.8 when left out",
        "modelURL": "the https URL of an .mlmodel the app downloads once, compiles on the device and keeps; no model ships in the package",
        "features": "the parts to write, of keywords, images, overlay and editor; all four when left out (the editor brings keywords)",
        "link": "whether to link the package into every app target of the .xcodeproj, or the Package.swift, in the project's folder; true when left out",
    ]
    public static let guide = """
        Tag moderation for on-device content safety in an app that shows what people post. One call writes a local \
        package (Packages/ModerationKit) with a keyword filter, an image-safety gate on a Core ML classifier the app \
        provides, a `ModerationPolicy` the app persists, a `Moderator` actor that judges each piece of content into \
        allow, blur or hide with the reason, a `censorOverlay(_:)` modifier and a `KeywordListEditor`, with tests; \
        then links it into every app target of the project (or the Package.swift) in the folder. The whole package \
        with nothing to choose: `{}`. Starter terms and a stricter image threshold: \
        `{"keywords": ["spoiler", "store-bought", "crypto*"], "threshold": 0.7}`; a term is matched as whole words in \
        any case or accents, a phrase word by word, and `*` stands for any letters (`crypto*`). No model ships in the \
        package: the app bundles its own classifier, or names one to download once with `modelURL`, and `label` is \
        the classifier's label for unsafe images: \
        `{"modelURL": "https://models.example.com/food-photo-safety.mlmodel", "label": "unsafe"}`. Text only: \
        `{"features": ["keywords", "editor"], "keywords": ["spoiler"]}`. Elsewhere and unlinked: \
        `{"name": "RecipeSafety", "into": "Packages/RecipeSafety", "link": false}`. Calling again with the same name \
        writes the package again and removes the parts left out; a folder holding another package is refused, and \
        every problem is said at once with nothing written. In the app: \
        `await moderator.judge(ModeratedContent(id: recipe.id, text: ["title": recipe.title], images: [.url(photo)]))`, \
        then `.censorOverlay(verdict)` on the card, and `KeywordListEditor(policy: $policy)` in settings. Not for \
        reporting, blocking accounts, or moderation a server does.
        """

    public static func output(from events: [ModerationFrame]) -> ModerationResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<ModerationFrame, Error> {
        var input = input
        if input.directory == nil { input.directory = context.host.directory }
        let call = input
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// One file a link edits: the project's or the manifest's, its new text, and what it says of the link.
    struct LinkEdit {
        var file: URL
        var text: String?
        var label: String
    }

    /// The whole call: the input read, the links planned, the package made, then everything staged, checked and
    /// written, and the files an earlier call wrote that this one leaves out removed.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (ModerationFrame) -> Void) throws -> ModerationResult {
        let files = AgentFiles(directory: input.directory)
        let (spec, specProblems) = ModerationSpec.read(input, files: files)
        var problems = specProblems
        var notes = spec.notes
        var links: [LinkEdit] = []
        if spec.link {
            let planned = planLinks(spec, files: files)
            links = planned.links
            notes += planned.notes
            problems += planned.problems
        }
        guard problems.isEmpty else { throw ModerationError.refused(problems) }

        let emitter = KitEmitter(spec: spec)
        let kit = try emitter.files()
        let parts = ModerationFeature.allCases.filter(spec.features.contains).map(\.rawValue)
        yield(.planned(files: kit.count, links: links.map(\.label)))
        note("writing \(spec.name) (\(parts.joined(separator: ", "))) into \(files.relative(spec.folder))")

        var planned = kit.map { (url: spec.folder.appendingPathComponent($0.path), text: $0.text) }
        planned += links.compactMap { link in link.text.map { (url: link.file, text: $0) } }
        let written = try files.write(planned)
        let removed = removeLeftOut(emitter.leftOut(), in: spec.folder)
        for link in links { note("linked into \(link.label)") }
        note("wrote \(written.count) file\(written.count == 1 ? "" : "s")")

        return ModerationResult(path: written.first, paths: written, package: spec.name, folder: files.relative(spec.folder),
                                features: parts, linked: links.map(\.label), removed: removed.map { files.relative($0) }, notes: notes)
    }

    /// The edits that link the package into the `.xcodeproj`s and the `Package.swift` in the host's folder.
    static func planLinks(_ spec: ModerationSpec, files: AgentFiles) -> (links: [LinkEdit], notes: [String], problems: [String]) {
        var links: [LinkEdit] = [], notes: [String] = [], problems: [String] = []
        let manager = FileManager.default
        let root = files.root
        let path = RelativePath.from(root, to: spec.folder)
        let projects = ((try? manager.contentsOfDirectory(atPath: root.path)) ?? []).filter { $0.hasSuffix(".xcodeproj") }.sorted()
        for name in projects {
            let file = root.appendingPathComponent(name).appendingPathComponent("project.pbxproj")
            guard let text = try? String(contentsOf: file, encoding: .utf8) else {
                notes.append("\(name) has no project file it could read, so the package was not linked into it.")
                continue
            }
            for folder in ProjectLinker.synchronizedFolders(text) where path == folder || path.hasPrefix(folder + "/") {
                problems.append("`into` \(path) lies in \(name)'s folder \(folder), whose files all join the app targets: put the package outside it, like Packages/\(spec.name)")
            }
            guard let outcome = ProjectLinker(product: spec.name, packagePath: path).link(text, project: name) else {
                notes.append("\(name) could not be read as a project, so the package was not linked into it.")
                continue
            }
            notes += outcome.notes
            if !outcome.targets.isEmpty {
                links.append(LinkEdit(file: file, text: outcome.text, label: "\(name) (\(outcome.targets.joined(separator: ", ")))"))
            }
        }
        let manifest = root.appendingPathComponent("Package.swift")
        if let text = try? String(contentsOf: manifest, encoding: .utf8) {
            let outcome = ManifestLinker(product: spec.name, packagePath: path, identity: spec.folder.lastPathComponent).link(text)
            notes += outcome.notes
            problems += outcome.problems
            if !outcome.targets.isEmpty, outcome.problems.isEmpty {
                links.append(LinkEdit(file: manifest, text: outcome.text, label: "Package.swift (\(outcome.targets.joined(separator: ", ")))"))
            }
        }
        if projects.isEmpty, !manager.fileExists(atPath: manifest.path) {
            notes.append("The project's folder holds no .xcodeproj or Package.swift, so the package was not linked.")
        }
        return (links, notes, problems)
    }

    /// Removes the files at `paths` in `folder` that an earlier call wrote, and the folders that leaves empty.
    static func removeLeftOut(_ paths: [String], in folder: URL) -> [URL] {
        let manager = FileManager.default
        var removed: [URL] = []
        for path in paths {
            let file = folder.appendingPathComponent(path)
            guard manager.fileExists(atPath: file.path), (try? manager.removeItem(at: file)) != nil else { continue }
            removed.append(file)
            var parent = file.deletingLastPathComponent()
            while parent.path.count > folder.path.count, (try? manager.contentsOfDirectory(atPath: parent.path))?.isEmpty == true {
                try? manager.removeItem(at: parent)
                parent = parent.deletingLastPathComponent()
            }
        }
        return removed
    }
}

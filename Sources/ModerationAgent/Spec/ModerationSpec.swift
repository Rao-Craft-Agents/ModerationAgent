//  WHAT: A call read and checked: the package's name and folder, its parts, the terms a new policy starts with, the
//        classifier's unsafe label, the score that blurs an image, and the model's download URL. What cannot be
//        honoured is refused with a sentence; what was quietly adjusted is said in a note.
//  PIN:  EVERY PROBLEM AT ONCE. Each field is checked even after one fails, so a model fixes the whole call in one
//        round instead of one problem a round.
//  PIN:  NEVER OVER SOMEONE ELSE'S PACKAGE. The folder must be empty, missing, or hold a package this agent wrote
//        under the same name (found by its moderator): a call regenerates its own package and nothing else.

import Foundation

struct ModerationSpec: Sendable {
    /// The package's name: its module, product and folder name.
    var name: String
    /// The package's folder, absolute.
    var folder: URL
    var features: Set<ModerationFeature>
    /// The terms a new policy starts with, as given, repeats dropped.
    var terms: [String]
    /// The classifier label that means unsafe.
    var label: String
    /// The score from which an image is blurred.
    var threshold: Double
    /// Where the app downloads its model when it names none.
    var modelURL: URL?
    /// Whether the package is linked into the project or package in the host's folder.
    var link: Bool
    /// What was adjusted, one sentence each.
    var notes: [String]

    static let defaultName = "ModerationKit"
    static let defaultLabel = "NSFW"
    static let defaultThreshold = 0.8

    /// The types the package declares, and the modules its files import: a module named like one would hide it.
    static let reservedNames: Set<String> = [
        "Moderator", "ModerationPolicy", "ModerationAction", "ModerationReason", "ModeratedContent", "ModeratedImage",
        "Verdict", "KeywordFilter", "KeywordMatch", "KeywordRule", "KeywordField", "KeywordListEditor", "ImageSafety",
        "ImageSafetyError", "CoreMLImageSafety", "CensorOverlay", "Foundation", "SwiftUI", "CoreML", "Vision",
        "CoreGraphics", "ImageIO", "XCTest", "Swift", "Testing",
    ]

    /// `input` read against the host's folder: the spec, and every reason it cannot be honoured.
    static func read(_ input: ModerationAgent.Input, files: AgentFiles) -> (spec: ModerationSpec, problems: [String]) {
        var problems: [String] = []
        var notes: [String] = []

        let name = (input.name ?? defaultName).trimmingCharacters(in: .whitespacesAndNewlines)
        if name.range(of: #"^[A-Z][A-Za-z0-9_]*$"#, options: .regularExpression) == nil {
            problems.append("`name` \(quoted(name)) is not a package name: UpperCamelCase letters and digits, like \(defaultName)")
        } else if reservedNames.contains(name) {
            problems.append("`name` \(name) is a type or module the package already uses: name the package something else, like \(defaultName)")
        }

        var features = Set(input.features ?? [])
        if features.isEmpty { features = Set(ModerationFeature.allCases) }
        if features.contains(.editor), !features.contains(.keywords) {
            features.insert(.keywords)
            notes.append("The keyword editor edits the keyword list, so keywords were added to the features.")
        }
        if !features.contains(.keywords), !features.contains(.images) {
            problems.append("`features` names neither keywords nor images, so the moderator would have nothing to judge: add one of them")
        }

        var terms: [String] = []
        var seen: Set<String> = []
        var repeats = 0
        for raw in input.keywords ?? [] {
            let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if term.isEmpty { continue }
            if term.contains(where: \.isNewline) {
                problems.append("keyword \(quoted(term)) has a line break: give one word or phrase an item")
            } else if !term.contains(where: { $0.isLetter || $0.isNumber }) {
                problems.append("keyword \(quoted(term)) has no letter or digit, so it can never match: drop it")
            } else if seen.insert(key(for: term)).inserted {
                terms.append(term)
            } else {
                repeats += 1
            }
        }
        if repeats > 0 { notes.append("\(repeats) repeated keyword\(repeats == 1 ? " was" : "s were") listed once.") }

        let label = (input.label ?? defaultLabel).trimmingCharacters(in: .whitespacesAndNewlines)
        if label.isEmpty || label.contains(where: \.isNewline) {
            problems.append("`label` must be the classifier's label for unsafe images, one line, like NSFW")
        }

        let threshold = input.threshold ?? defaultThreshold
        if !(threshold > 0 && threshold <= 1) {
            problems.append("`threshold` \(threshold) is not a score: give a number above 0 and at most 1, like 0.8")
        }

        var modelURL: URL?
        if let text = input.modelURL?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
            if let url = URL(string: text), let scheme = url.scheme?.lowercased(), url.host?.isEmpty == false {
                let ext = url.pathExtension.lowercased()
                if scheme == "http" {
                    problems.append("`modelURL` uses http, which App Transport Security blocks: give its https address")
                } else if scheme != "https" {
                    problems.append("`modelURL` \(text) is not a web address: give the https URL of an .mlmodel file")
                } else if ["zip", "mlpackage", "mlmodelc"].contains(ext) {
                    problems.append("`modelURL` names a .\(ext); the package downloads one .mlmodel file and compiles it on the device: give that file's URL")
                } else {
                    modelURL = url
                }
            } else {
                problems.append("`modelURL` \(quoted(text)) is not a URL: give the https URL of an .mlmodel file")
            }
        }

        var unused: [String] = []
        if !features.contains(.keywords), !(input.keywords ?? []).isEmpty { unused.append("`keywords`") }
        if !features.contains(.images) {
            if input.label != nil { unused.append("`label`") }
            if input.threshold != nil { unused.append("`threshold`") }
            if input.modelURL != nil { unused.append("`modelURL`") }
        }
        if !unused.isEmpty {
            notes.append("\(unused.joined(separator: ", ")) went unused: the features leave out what \(unused.count == 1 ? "it is" : "they are") for.")
        }

        let folder = files.resolve(input.into ?? "Packages/\(name)")
        problems += folderProblems(folder, name: name, files: files)

        let spec = ModerationSpec(name: name, folder: folder, features: features, terms: terms, label: label, threshold: threshold,
                                  modelURL: modelURL, link: input.link ?? true, notes: notes)
        return (spec, problems)
    }

    /// Why the package cannot be written into `folder`, if it cannot.
    static func folderProblems(_ folder: URL, name: String, files: AgentFiles) -> [String] {
        let shown = files.relative(folder)
        if folder.path == files.root.path {
            return ["`into` names the project's own folder: give the package a folder of its own, like Packages/\(name)"]
        }
        if folder.pathComponents.contains(where: { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }) {
            return ["`into` \(shown) lies inside an Xcode project bundle: give the package a folder of its own, like Packages/\(name)"]
        }
        let manager = FileManager.default
        var isFolder: ObjCBool = false
        guard manager.fileExists(atPath: folder.path, isDirectory: &isFolder) else { return [] }
        guard isFolder.boolValue else { return ["`into` \(shown) is a file: give the package a folder"] }
        let contents = ((try? manager.contentsOfDirectory(atPath: folder.path)) ?? []).filter { $0 != ".DS_Store" }
        if contents.isEmpty { return [] }
        let moderator = folder.appendingPathComponent("Sources/\(name)/Moderation/Moderator.swift")
        let ours = contents.contains("Package.swift")
            && ((try? String(contentsOf: moderator, encoding: .utf8))?.contains("public actor Moderator") ?? false)
        if ours { return [] }
        if contents.contains("Package.swift") {
            return ["\(shown) already holds a package this agent did not write as \(name): choose another `into`, or another `name`"]
        }
        return ["\(shown) already holds files: choose an empty folder for the package, or leave `into` out"]
    }

    /// A term as it is compared for repeats: its words folded and joined, so `Spoil*  ALERT` is `spoil* alert`.
    static func key(for term: String) -> String {
        term.split { !($0.isLetter || $0.isNumber || $0 == "*") }
            .map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil) }
            .joined(separator: " ")
    }

    private static func quoted(_ text: String) -> String {
        "`\(text.count > 60 ? String(text.prefix(57)) + "..." : text)`"
    }
}

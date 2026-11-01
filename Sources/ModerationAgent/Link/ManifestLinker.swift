//  WHAT: A local package linked into a Swift package's manifest by editing `Package.swift` as text: the dependency
//        `.package(path:)`, the product on every regular and executable target, and the platforms raised to the
//        lowest the package builds for.
//  PIN:  PLANNED ON THE TEXT AS READ, MADE FROM THE END. Every edit is found on the manifest as it was, then made
//        from the last to the first, so no edit moves another's place.
//  PIN:  IDEMPOTENT. A dependency, a product or a platform already there is left as it is.
//  PIN:  A MANIFEST IT CANNOT READ IS NOT GUESSED AT. When `Package(…)` or its lists are not literals it can read,
//        the package is still written, and a note says the two lines to add by hand.

import Foundation

struct ManifestLinker {
    /// What linking did to the manifest.
    struct Outcome {
        /// The manifest's new text; nil when it already linked the package, or could not be read.
        var text: String?
        /// The targets that depend on the product.
        var targets: [String]
        var notes: [String]
        /// Why the package cannot be linked here.
        var problems: [String]
    }

    /// The product the targets depend on: the package's name.
    let product: String
    /// The package's folder, relative to the manifest's.
    let packagePath: String
    /// The package's identity: its folder's name.
    let identity: String
    /// The lowest versions the package builds for, by the manifest's platform names.
    var minimums: [(platform: String, major: Int)] = [("iOS", 17), ("macOS", 14)]

    private typealias Edit = (range: Range<Int>, text: String)

    func link(_ manifest: String) -> Outcome {
        let source = SwiftText(manifest)
        guard let open = source.call("Package"), source.closing(from: open) != nil else {
            return Outcome(text: nil, targets: [], notes: [unreadable("its `Package(…)` could not be read")], problems: [])
        }
        let arguments = source.pieces(inside: open)
        guard let targetsArgument = arguments.first(where: { $0.label == "targets" }), isArray(targetsArgument, in: source) else {
            return Outcome(text: nil, targets: [], notes: [unreadable("its `targets:` is not a list it could read")], problems: [])
        }
        var edits: [Edit] = []
        var notes: [String] = []
        var problems: [String] = []
        var targets: [String] = []

        // The product on every regular and executable target.
        let productLiteral = ".product(name: \(SwiftLiteral.string(product)), package: \(SwiftLiteral.string(identity)))"
        for element in source.pieces(inside: targetsArgument.value.lowerBound) {
            let text = source.string(element.value)
            guard text.hasPrefix(".target(") || text.hasPrefix(".executableTarget("),
                  let call = source.bytes[element.value].firstIndex(of: UInt8(ascii: "(")) else { continue }
            let parts = source.pieces(inside: call)
            guard let nameArgument = parts.first(where: { $0.label == "name" }) else { continue }
            let name = source.string(nameArgument.value).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if name == product {
                problems.append("the package in the project's folder already has a target named \(product): give `name` another name, like SafetyKit")
                continue
            }
            targets.append(name)
            if let dependencies = parts.first(where: { $0.label == "dependencies" }) {
                guard isArray(dependencies, in: source) else {
                    notes.append(unreadable("the dependencies of target \(name) are not a list it could read"))
                    continue
                }
                let items = source.pieces(inside: dependencies.value.lowerBound)
                if items.contains(where: { mentionsProduct(source.string($0.value)) }) { continue }
                edits += append([productLiteral], toArrayAt: dependencies.value.lowerBound, items: items, in: source)
            } else {
                let next = parts.first { $0.whole.lowerBound > nameArgument.whole.lowerBound }
                let ownLine = next.map { source.breaksLine(nameArgument.whole.upperBound, $0.whole.lowerBound) } ?? false
                let separator = ownLine ? ",\n" + source.indentation(of: nameArgument.whole.lowerBound) : ", "
                edits.append((nameArgument.whole.upperBound..<nameArgument.whole.upperBound, "\(separator)dependencies: [\(productLiteral)]"))
            }
        }

        // The package among the manifest's dependencies.
        let dependencyLiteral = ".package(path: \(SwiftLiteral.string(packagePath)))"
        if let dependencies = arguments.first(where: { $0.label == "dependencies" }) {
            if isArray(dependencies, in: source) {
                let items = source.pieces(inside: dependencies.value.lowerBound)
                if !items.contains(where: { isPackage(source.string($0.value)) }) {
                    edits += append([dependencyLiteral], toArrayAt: dependencies.value.lowerBound, items: items, in: source)
                }
            } else {
                notes.append(unreadable("its `dependencies:` is not a list it could read"))
            }
        } else {
            edits.append(argument("dependencies", [dependencyLiteral], before: targetsArgument, among: arguments, in: source))
        }

        // The platforms, raised to what the package needs.
        if let platforms = arguments.first(where: { $0.label == "platforms" }) {
            if isArray(platforms, in: source) {
                let items = source.pieces(inside: platforms.value.lowerBound)
                var missing: [String] = []
                for (platform, major) in minimums {
                    guard let item = items.first(where: { source.string($0.value).hasPrefix(".\(platform)(") }) else {
                        missing.append(".\(platform)(.v\(major))")
                        continue
                    }
                    let written = source.string(item.value)
                    if let version = Self.version(written), ProjectLinker.version(version, isBelow: "\(major)") {
                        edits.append((item.value, ".\(platform)(.v\(major))"))
                        notes.append("Package.swift's \(platform) platform was raised from \(version) to \(major), the lowest the package builds for.")
                    }
                }
                if !missing.isEmpty {
                    edits += append(missing, toArrayAt: platforms.value.lowerBound, items: items, in: source)
                    notes.append("Package.swift now names \(missing.joined(separator: " and ")) among its platforms, the lowest the package builds for.")
                }
            }
        } else {
            let literals = minimums.map { ".\($0.platform)(.v\($0.major))" }
            let anchor = arguments.first { $0.label == "defaultLocalization" } ?? arguments.first { $0.label == "name" }
            if let anchor, let next = arguments.first(where: { $0.whole.lowerBound > anchor.whole.lowerBound }) {
                edits.append(argument("platforms", literals, before: next, among: arguments, in: source))
                notes.append("Package.swift now names its platforms, \(literals.joined(separator: " and ")), the lowest the package builds for.")
            }
        }

        guard problems.isEmpty else { return Outcome(text: nil, targets: targets, notes: notes, problems: problems) }
        var bytes = source.bytes
        for edit in edits.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            bytes.replaceSubrange(edit.range, with: Array(edit.text.utf8))
        }
        let text = String(decoding: bytes, as: UTF8.self)
        return Outcome(text: text == manifest ? nil : text, targets: targets, notes: notes, problems: [])
    }

    // MARK: - Editing

    /// The edits that add `literals` at the end of the array whose `[` is at `open`, in the array's own layout.
    private func append(_ literals: [String], toArrayAt open: Int, items: [SwiftText.Piece], in source: SwiftText) -> [Edit] {
        guard let close = source.closing(from: open) else { return [] }
        let joined = literals.joined(separator: ", ")
        guard let last = items.last else {
            if source.breaksLine(open, close) {
                let line = source.lineStart(of: close)
                return [(line..<line, source.indentation(of: close) + "    " + joined + ",\n")]
            }
            return [((open + 1)..<close, joined)]
        }
        if source.breaksLine(last.whole.upperBound, close) {
            var edits: [Edit] = []
            if source.comma(after: last.whole.upperBound) == nil { edits.append((last.whole.upperBound..<last.whole.upperBound, ",")) }
            let line = source.lineStart(of: close)
            edits.append((line..<line, source.indentation(of: last.whole.lowerBound) + joined + ",\n"))
            return edits
        }
        if let past = source.comma(after: last.whole.upperBound) { return [(past..<past, " \(joined),")] }
        return [(last.whole.upperBound..<last.whole.upperBound, ", \(joined)")]
    }

    /// The edit that adds the argument `label: [literals]` just before `next`, in the call's own layout.
    private func argument(_ label: String, _ literals: [String], before next: SwiftText.Piece, among arguments: [SwiftText.Piece],
                          in source: SwiftText) -> Edit {
        let previous = arguments.last { $0.whole.upperBound <= next.whole.lowerBound }
        let ownLine = previous.map { source.breaksLine($0.whole.upperBound, next.whole.lowerBound) } ?? true
        if ownLine {
            let indent = source.indentation(of: next.whole.lowerBound)
            let line = source.lineStart(of: next.whole.lowerBound)
            let body = literals.count == 1
                ? "[\n\(indent)    \(literals[0]),\n\(indent)]"
                : "[\(literals.joined(separator: ", "))]"
            return (line..<line, "\(indent)\(label): \(body),\n")
        }
        return (next.whole.lowerBound..<next.whole.lowerBound, "\(label): [\(literals.joined(separator: ", "))], ")
    }

    // MARK: - Reading

    private func isArray(_ piece: SwiftText.Piece, in source: SwiftText) -> Bool {
        !piece.value.isEmpty && source.bytes[piece.value.lowerBound] == UInt8(ascii: "[")
    }

    /// Whether `element` is this package's `.package(path:)`.
    private func isPackage(_ element: String) -> Bool {
        let path = NSRegularExpression.escapedPattern(for: ProjectLinker.normalized(packagePath))
        return element.range(of: #"^\.package\(\s*(name:\s*"[^"]*"\s*,\s*)?path:\s*"(\./)?"# + path + #"/?"\s*\)$"#, options: .regularExpression) != nil
    }

    /// Whether `element` is a dependency on the product.
    private func mentionsProduct(_ element: String) -> Bool {
        let name = NSRegularExpression.escapedPattern(for: product)
        return element.range(of: #"^\.product\(\s*name:\s*""# + name + #"""#, options: .regularExpression) != nil
    }

    /// The version a platform element names: `.macOS(.v13_5)` is `13.5`, `.iOS("16.4")` is `16.4`.
    static func version(_ element: String) -> String? {
        if let range = element.range(of: #"\.v[0-9]+(_[0-9]+)*"#, options: .regularExpression) {
            return element[range].dropFirst(2).replacingOccurrences(of: "_", with: ".")
        }
        if let range = element.range(of: #""[0-9]+(\.[0-9]+)*""#, options: .regularExpression) {
            return element[range].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    private func unreadable(_ why: String) -> String {
        "Package.swift was not linked: \(why). Add `.package(path: \"\(packagePath)\")` to its dependencies and `\(".product(name: \"\(product)\", package: \"\(identity)\")")` to a target's."
    }
}

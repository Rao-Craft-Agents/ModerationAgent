//  WHAT: A template made into a file: `{{key}}` replaced by its value, and the lines between `{{#section}}` and
//        `{{/section}}` kept only when the section is on (between `{{^section}}` and `{{/section}}`, only when it
//        is off). Section tags stand on lines of their own, and those lines go with them; sections nest.
//  PIN:  A TAG IT DOES NOT KNOW IS A FAULT OF THE TEMPLATE, NOT OF THE CALL. Tests render every template with
//        every set of parts, so no fault reaches a call.

import Foundation

enum TemplateRenderer {
    struct Fault: Error, Equatable, CustomStringConvertible {
        let description: String
    }

    static func render(_ template: String, values: [String: String], sections: Set<String>) throws -> String {
        var kept: [Substring] = []
        var open: [(name: String, keeps: Bool)] = []
        for line in template.split(separator: "\n", omittingEmptySubsequences: false) {
            if let tag = sectionTag(line) {
                switch tag.mark {
                case "#": open.append((tag.name, sections.contains(tag.name)))
                case "^": open.append((tag.name, !sections.contains(tag.name)))
                default:
                    guard open.last?.name == tag.name else { throw Fault(description: "`{{/\(tag.name)}}` closes no open section") }
                    open.removeLast()
                }
                continue
            }
            if open.allSatisfy(\.keeps) { kept.append(line) }
        }
        if let unclosed = open.last { throw Fault(description: "`{{#\(unclosed.name)}}` is never closed") }
        var text = kept.joined(separator: "\n")
        for (key, value) in values { text = text.replacingOccurrences(of: "{{\(key)}}", with: value) }
        if let stray = text.range(of: #"\{\{[#^/]?[A-Za-z][A-Za-z0-9]*\}\}"#, options: .regularExpression) {
            throw Fault(description: "`\(text[stray])` is not a value or a section tag on a line of its own")
        }
        return text
    }

    /// The section tag `line` holds alone, if it does: its mark (`#`, `^` or `/`) and its name.
    private static func sectionTag(_ line: Substring) -> (mark: Character, name: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("{{"), trimmed.hasSuffix("}}"), trimmed.count > 5 else { return nil }
        let inside = trimmed.dropFirst(2).dropLast(2)
        guard let mark = inside.first, "#^/".contains(mark) else { return nil }
        let name = String(inside.dropFirst())
        guard name.range(of: #"^[A-Za-z][A-Za-z0-9]*$"#, options: .regularExpression) != nil else { return nil }
        return (mark, name)
    }
}

//  WHAT: A Swift manifest read where it must be edited: the bracket that closes another, a call's arguments and an
//        array's elements split at their own commas, strings and comments skipped the way the compiler skips them.
//  PIN:  BYTES, NOT CHARACTERS, for the reason `PBXText` gives: every character with meaning here is ASCII.

import Foundation

struct SwiftText {
    /// One argument of a call, or one element of an array: its label when it has one, its value, and all of it.
    struct Piece {
        let label: String?
        let value: Range<Int>
        let whole: Range<Int>
    }

    let bytes: [UInt8]

    init(_ text: String) { bytes = Array(text.utf8) }

    func string(_ range: Range<Int>) -> String { String(decoding: bytes[range], as: UTF8.self) }

    /// The offset of the `(` of the first call of `name` in code (not in a string or a comment).
    func call(_ name: String) -> Int? {
        let word = Array(name.utf8)
        var index = 0
        while index < bytes.count {
            if let skipped = skip(at: index) { index = skipped; continue }
            if bytes[index...].starts(with: word), index == 0 || !isIdentifier(bytes[index - 1]),
               index + word.count < bytes.count, !isIdentifier(bytes[index + word.count]) {
                var open = index + word.count
                while open < bytes.count, bytes[open] == UInt8(ascii: " ") || bytes[open] == UInt8(ascii: "\n") || bytes[open] == UInt8(ascii: "\t") { open += 1 }
                if open < bytes.count, bytes[open] == UInt8(ascii: "(") { return open }
            }
            index += 1
        }
        return nil
    }

    /// The offset of the bracket that closes the `(`, `[` or `{` at `open`.
    func closing(from open: Int) -> Int? {
        var depth = 0
        var index = open
        while index < bytes.count {
            if let skipped = skip(at: index) { index = skipped; continue }
            switch bytes[index] {
            case UInt8(ascii: "("), UInt8(ascii: "["), UInt8(ascii: "{"): depth += 1
            case UInt8(ascii: ")"), UInt8(ascii: "]"), UInt8(ascii: "}"):
                depth -= 1
                if depth == 0 { return index }
            default: break
            }
            index += 1
        }
        return nil
    }

    /// The pieces between the bracket at `open` and the one that closes it, split at their own commas.
    func pieces(inside open: Int) -> [Piece] {
        guard let close = closing(from: open) else { return [] }
        var pieces: [Piece] = []
        var start = open + 1
        var depth = 0
        var index = open + 1
        func finish(_ end: Int) {
            let whole = trimmed(start..<end)
            guard !whole.isEmpty else { return }
            var label: String?
            var value = whole
            var cursor = whole.lowerBound
            while cursor < whole.upperBound, isIdentifier(bytes[cursor]) { cursor += 1 }
            var colon = cursor
            while colon < whole.upperBound, bytes[colon] == UInt8(ascii: " ") { colon += 1 }
            if cursor > whole.lowerBound, colon < whole.upperBound, bytes[colon] == UInt8(ascii: ":") {
                label = string(whole.lowerBound..<cursor)
                value = trimmed((colon + 1)..<whole.upperBound)
            }
            pieces.append(Piece(label: label, value: value, whole: whole))
        }
        while index < close {
            if let skipped = skip(at: index) { index = skipped; continue }
            switch bytes[index] {
            case UInt8(ascii: "("), UInt8(ascii: "["), UInt8(ascii: "{"): depth += 1
            case UInt8(ascii: ")"), UInt8(ascii: "]"), UInt8(ascii: "}"): depth -= 1
            case UInt8(ascii: ",") where depth == 0:
                finish(index)
                start = index + 1
            default: break
            }
            index += 1
        }
        finish(close)
        return pieces
    }

    /// Whether a newline stands between `start` and `end`.
    func breaksLine(_ start: Int, _ end: Int) -> Bool {
        start < end && bytes[start..<end].contains(UInt8(ascii: "\n"))
    }

    /// The spaces and tabs the line holding `offset` starts with.
    func indentation(of offset: Int) -> String {
        var start = offset
        while start > 0, bytes[start - 1] != UInt8(ascii: "\n") { start -= 1 }
        var end = start
        while end < bytes.count, bytes[end] == UInt8(ascii: " ") || bytes[end] == UInt8(ascii: "\t") { end += 1 }
        return string(start..<end)
    }

    /// Where the line holding `offset` starts.
    func lineStart(of offset: Int) -> Int {
        var start = offset
        while start > 0, bytes[start - 1] != UInt8(ascii: "\n") { start -= 1 }
        return start
    }

    /// The offset just past the comma that follows `end` (spaces and comments between), if one does.
    func comma(after end: Int) -> Int? {
        var index = end
        while index < bytes.count {
            if let skipped = skip(at: index) { index = skipped; continue }
            let byte = bytes[index]
            if byte == UInt8(ascii: ",") { return index + 1 }
            if byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\t") || byte == UInt8(ascii: "\r") { index += 1; continue }
            return nil
        }
        return nil
    }

    // MARK: - Scanning

    /// Past the string or comment that starts at `index`; nil when none does.
    private func skip(at index: Int) -> Int? {
        let byte = bytes[index]
        if byte == UInt8(ascii: "/"), index + 1 < bytes.count {
            if bytes[index + 1] == UInt8(ascii: "/") {
                var end = index
                while end < bytes.count, bytes[end] != UInt8(ascii: "\n") { end += 1 }
                return end
            }
            if bytes[index + 1] == UInt8(ascii: "*") {
                var depth = 0, end = index
                while end + 1 < bytes.count {
                    if bytes[end] == UInt8(ascii: "/"), bytes[end + 1] == UInt8(ascii: "*") { depth += 1; end += 2; continue }
                    if bytes[end] == UInt8(ascii: "*"), bytes[end + 1] == UInt8(ascii: "/") {
                        depth -= 1; end += 2
                        if depth == 0 { return end }
                        continue
                    }
                    end += 1
                }
                return bytes.count
            }
        }
        var hashes = 0
        var quote = index
        while quote < bytes.count, bytes[quote] == UInt8(ascii: "#") { hashes += 1; quote += 1 }
        guard quote < bytes.count, bytes[quote] == UInt8(ascii: "\"") else { return nil }
        if hashes > 0, index > 0, isIdentifier(bytes[index - 1]) { return nil }
        let multiline = bytes[quote...].starts(with: Array("\"\"\"".utf8))
        let delimiter = Array((multiline ? "\"\"\"" : "\"").utf8) + Array(repeating: UInt8(ascii: "#"), count: hashes)
        var end = quote + (multiline ? 3 : 1)
        while end < bytes.count {
            if bytes[end] == UInt8(ascii: "\\") {
                let afterHashes = end + 1 + hashes
                if bytes[(end + 1)..<min(afterHashes, bytes.count)].allSatisfy({ $0 == UInt8(ascii: "#") }),
                   afterHashes < bytes.count, bytes[afterHashes] == UInt8(ascii: "(") {
                    end = (closing(from: afterHashes) ?? bytes.count - 1) + 1
                    continue
                }
                end += 2
                continue
            }
            if bytes[end...].starts(with: delimiter) { return end + delimiter.count }
            end += 1
        }
        return bytes.count
    }

    private func trimmed(_ range: Range<Int>) -> Range<Int> {
        var lower = range.lowerBound, upper = range.upperBound
        while lower < upper, isSpace(bytes[lower]) || startsComment(lower) {
            if startsComment(lower), let skipped = skip(at: lower) { lower = skipped } else { lower += 1 }
        }
        while upper > lower, isSpace(bytes[upper - 1]) { upper -= 1 }
        return lower..<upper
    }

    private func startsComment(_ index: Int) -> Bool {
        index + 1 < bytes.count && bytes[index] == UInt8(ascii: "/") && (bytes[index + 1] == UInt8(ascii: "/") || bytes[index + 1] == UInt8(ascii: "*"))
    }

    private func isSpace(_ byte: UInt8) -> Bool {
        byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\t") || byte == UInt8(ascii: "\r")
    }

    private func isIdentifier(_ byte: UInt8) -> Bool {
        (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z")) || (byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z"))
            || (byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")) || byte == UInt8(ascii: "_")
    }
}

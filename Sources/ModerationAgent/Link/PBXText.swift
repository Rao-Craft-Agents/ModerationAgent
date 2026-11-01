//  WHAT: An Xcode project file as text to edit: where an object is defined, its entries and their values, the end
//        of a list or a section, read the way the plist reader reads them (quoted strings and comments skipped), and
//        text inserted or replaced at a place.
//  PIN:  BYTES, NOT CHARACTERS. Every character the format gives meaning to is ASCII, and no byte of a multi-byte
//        UTF-8 character is, so the file is read and edited as bytes: fast on a large project, and exact.

import Foundation

struct PBXText {
    /// An entry of a dictionary: its key, where the line holding it starts, and where its value lies.
    struct Entry {
        let key: String
        let line: Int
        let value: Range<Int>
    }

    private(set) var bytes: [UInt8]

    init(_ text: String) { bytes = Array(text.utf8) }

    var text: String { String(decoding: bytes, as: UTF8.self) }

    func contains(_ string: String) -> Bool { bytes.firstRange(of: Array(string.utf8)) != nil }

    func string(_ range: Range<Int>) -> String { String(decoding: bytes[range], as: UTF8.self) }

    mutating func insert(_ string: String, at offset: Int) { bytes.insert(contentsOf: Array(string.utf8), at: offset) }

    mutating func replace(_ range: Range<Int>, with string: String) { bytes.replaceSubrange(range, with: Array(string.utf8)) }

    // MARK: - Reading

    /// The `{` of object `id`'s definition: `ID /* comment */ = {` at the start of a line.
    func objectOpen(_ id: String) -> Int? {
        let needle = Array(id.utf8)
        var from = 0
        while let found = bytes[from...].firstRange(of: needle) {
            from = found.upperBound
            guard isBlank(lineStart(of: found.lowerBound)..<found.lowerBound) else { continue }
            var index = skipSpaceAndComments(from: found.upperBound)
            guard index < bytes.count, bytes[index] == UInt8(ascii: "=") else { continue }
            index = skipSpaceAndComments(from: index + 1)
            if index < bytes.count, bytes[index] == UInt8(ascii: "{") { return index }
        }
        return nil
    }

    /// The offset of the `}` or `)` that closes the `{` or `(` at `open`.
    func closing(from open: Int) -> Int? {
        var depth = 0
        var index = open
        while index < bytes.count {
            switch bytes[index] {
            case UInt8(ascii: "\""):
                index = endOfString(from: index)
                continue
            case UInt8(ascii: "/") where index + 1 < bytes.count && (bytes[index + 1] == UInt8(ascii: "*") || bytes[index + 1] == UInt8(ascii: "/")):
                index = skipComment(from: index)
                continue
            case UInt8(ascii: "{"), UInt8(ascii: "("):
                depth += 1
            case UInt8(ascii: "}"), UInt8(ascii: ")"):
                depth -= 1
                if depth == 0 { return index }
            default:
                break
            }
            index += 1
        }
        return nil
    }

    /// The entries of the dictionary whose `{` is at `open`, in order.
    func entries(ofDictionaryAt open: Int) -> [Entry] {
        guard let close = closing(from: open) else { return [] }
        var entries: [Entry] = []
        var index = skipSpaceAndComments(from: open + 1)
        while index < close {
            let keyStart = index
            let keyEnd = endOfToken(from: index)
            guard keyEnd > keyStart else { break }
            let key = string(keyStart..<keyEnd).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            index = skipSpaceAndComments(from: keyEnd)
            guard index < close, bytes[index] == UInt8(ascii: "=") else { break }
            let valueStart = skipSpaceAndComments(from: index + 1)
            guard valueStart < close else { break }
            let valueEnd: Int
            if bytes[valueStart] == UInt8(ascii: "{") || bytes[valueStart] == UInt8(ascii: "(") {
                guard let end = closing(from: valueStart) else { break }
                valueEnd = end + 1
            } else {
                valueEnd = endOfToken(from: valueStart)
            }
            entries.append(Entry(key: key, line: lineStart(of: keyStart), value: valueStart..<valueEnd))
            index = skipSpaceAndComments(from: valueEnd)
            guard index < close, bytes[index] == UInt8(ascii: ";") else { break }
            index = skipSpaceAndComments(from: index + 1)
        }
        return entries
    }

    /// The items of the list whose `(` is at `open`: each item's value, without its comment.
    func items(ofListAt open: Int) -> [(value: String, range: Range<Int>)] {
        guard let close = closing(from: open) else { return [] }
        var items: [(String, Range<Int>)] = []
        var index = skipSpaceAndComments(from: open + 1)
        while index < close {
            let end = endOfToken(from: index)
            guard end > index else { break }
            items.append((string(index..<end).trimmingCharacters(in: CharacterSet(charactersIn: "\"")), index..<end))
            index = skipSpaceAndComments(from: end)
            if index < close, bytes[index] == UInt8(ascii: ",") { index = skipSpaceAndComments(from: index + 1) }
        }
        return items
    }

    /// Where the line holding `offset` starts.
    func lineStart(of offset: Int) -> Int {
        var index = min(offset, bytes.count)
        while index > 0, bytes[index - 1] != UInt8(ascii: "\n") { index -= 1 }
        return index
    }

    /// Where the line holding `offset` ends: just past its newline.
    func lineEnd(of offset: Int) -> Int {
        var index = offset
        while index < bytes.count, bytes[index] != UInt8(ascii: "\n") { index += 1 }
        return min(index + 1, bytes.count)
    }

    /// The tabs and spaces a line starts with.
    func indentation(ofLineAt start: Int) -> String {
        var end = start
        while end < bytes.count, bytes[end] == UInt8(ascii: "\t") || bytes[end] == UInt8(ascii: " ") { end += 1 }
        return string(start..<end)
    }

    /// Whether `range` holds only tabs and spaces.
    func isBlank(_ range: Range<Int>) -> Bool {
        bytes[range].allSatisfy { $0 == UInt8(ascii: "\t") || $0 == UInt8(ascii: " ") }
    }

    /// The offset of the first `marker` (a section's `/* Begin … */`, say), if any.
    func offset(of marker: String) -> Int? { bytes.firstRange(of: Array(marker.utf8))?.lowerBound }

    // MARK: - Scanning

    private func skipSpaceAndComments(from start: Int) -> Int {
        var index = start
        while index < bytes.count {
            let byte = bytes[index]
            if byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") || byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\r") {
                index += 1
            } else if byte == UInt8(ascii: "/"), index + 1 < bytes.count, bytes[index + 1] == UInt8(ascii: "*") || bytes[index + 1] == UInt8(ascii: "/") {
                index = skipComment(from: index)
            } else {
                break
            }
        }
        return index
    }

    private func skipComment(from start: Int) -> Int {
        if bytes[start + 1] == UInt8(ascii: "/") { return lineEnd(of: start) }
        var index = start + 2
        while index + 1 < bytes.count, !(bytes[index] == UInt8(ascii: "*") && bytes[index + 1] == UInt8(ascii: "/")) { index += 1 }
        return min(index + 2, bytes.count)
    }

    /// Just past the quoted string that starts at `start`.
    private func endOfString(from start: Int) -> Int {
        var index = start + 1
        while index < bytes.count {
            if bytes[index] == UInt8(ascii: "\\") { index += 2; continue }
            if bytes[index] == UInt8(ascii: "\"") { return index + 1 }
            index += 1
        }
        return bytes.count
    }

    /// Just past the string or bare word at `start`.
    private func endOfToken(from start: Int) -> Int {
        guard start < bytes.count else { return start }
        if bytes[start] == UInt8(ascii: "\"") { return endOfString(from: start) }
        var index = start
        let stops: Set<UInt8> = Set("{}();,=\" \t\r\n".utf8)
        while index < bytes.count, !stops.contains(bytes[index]) {
            if bytes[index] == UInt8(ascii: "/"), index + 1 < bytes.count, bytes[index + 1] == UInt8(ascii: "*") { break }
            index += 1
        }
        return index
    }
}

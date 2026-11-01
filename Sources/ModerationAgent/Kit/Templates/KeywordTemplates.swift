//  WHAT: The generated package's keyword filter: words read and folded, terms compiled into a tree, matched in one pass.
//  PIN:  EDIT THE TEMPLATE, THEN BUILD IT. `MODERATION_BUILD=1 swift test` renders every set of parts and builds
//        and tests each package for real.

import Foundation

enum KeywordTemplates {
    static let token = KitTemplate("Sources/{{name}}/Keywords/KeywordToken.swift", needs: [.keywords], text: ##"""
//  WHAT: One word of a text as the keyword filter reads it: folded, and where it stands.

import Foundation

/// One word of a text: folded, and where it stands in the text it was read from.
struct KeywordToken: Sendable {
    /// The word as it is compared: lowercase, without accents, at full width.
    let folded: String
    /// Where the word stands in the text.
    let range: Range<String.Index>
}
"""##)

    static let tokenizer = KitTemplate("Sources/{{name}}/Keywords/KeywordTokenizer.swift", needs: [.keywords], text: ##"""
//  WHAT: Text cut into the words a keyword is matched against, each folded (case, accents and width dropped) and
//        kept with where it stands. Terms are cut the same way, so `Café` in a list and `CAFE` in a post are one
//        word.
//  PIN:  ONE RULE FOR TERMS AND TEXT. A word is a run of letters and digits; an apostrophe inside a word is dropped
//        (`don't` reads `dont`); any other character ends a word. A character of a script written without spaces
//        (Han, kana, Thai, Lao, Khmer, Myanmar) is a word of its own, so a term in those scripts is found inside a
//        longer run of them.

import Foundation

enum KeywordTokenizer {
    /// The words of `text`, in order. With `wildcards`, `*` is part of a word: how a term is read.
    static func tokens(in text: String, wildcards: Bool = false) -> [KeywordToken] {
        var tokens: [KeywordToken] = []
        var start: String.Index?
        var word = ""
        func close(at end: String.Index) {
            if let begin = start, !word.isEmpty { tokens.append(KeywordToken(folded: fold(word), range: begin..<end)) }
            start = nil
            word = ""
        }
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)
            if isUnspaced(character) {
                close(at: index)
                tokens.append(KeywordToken(folded: fold(String(character)), range: index..<next))
            } else if isApostrophe(character) {
                // Inside a word it joins the word (`don't`); anywhere else it ends one.
                if start == nil || next == text.endIndex || !isWordCharacter(text[next]) { close(at: index) }
            } else if isWordCharacter(character) || (wildcards && character == "*") {
                if start == nil { start = index }
                word.append(character)
            } else {
                close(at: index)
            }
            index = next
        }
        close(at: text.endIndex)
        return tokens
    }

    /// `word` as it is compared: lowercase, without accents, at full width (`ＳＴＲＡßE` is `strasse`).
    static func fold(_ word: String) -> String {
        if word.utf8.allSatisfy({ $0 < 0x80 }) { return word.lowercased() }
        return word.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }

    static func isApostrophe(_ character: Character) -> Bool {
        character == "'" || character == "\u{2019}" || character == "\u{02BC}"
    }

    /// Whether `character` belongs to a script written without spaces between words.
    static func isUnspaced(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x0E00...0x0EFF,    // Thai, Lao
             0x1000...0x109F,    // Myanmar
             0x1780...0x17FF,    // Khmer
             0x3040...0x30FF,    // Hiragana, Katakana
             0x31F0...0x31FF,    // Katakana extensions
             0x3400...0x4DBF,    // CJK extension A
             0x4E00...0x9FFF,    // CJK unified ideographs
             0xF900...0xFAFF,    // CJK compatibility ideographs
             0xFF66...0xFF9F,    // Halfwidth katakana
             0x20000...0x323AF:  // CJK extensions B and on
            return true
        default:
            return false
        }
    }
}
"""##)

    static let pattern = KitTemplate("Sources/{{name}}/Keywords/KeywordPattern.swift", needs: [.keywords], text: ##"""
//  WHAT: One word of a term: a word to equal, or a word with `*` standing for any letters in it (`spoil*`,
//        `*coin`, `*ware*`, `c*t`), or `*` alone, standing for any one word of a phrase.

import Foundation

enum KeywordPattern: Hashable, Sendable {
    /// The word itself.
    case word(String)
    /// `*`: any one word.
    case any
    /// `spoil*`: a word that starts with it.
    case prefix(String)
    /// `*coin`: a word that ends with it.
    case suffix(String)
    /// `*ware*`: a word that holds it.
    case infix(String)
    /// `c*t`, `a*b*c`: the pieces in order, the first at the start and the last at the end unless a star stands there.
    case pieces([String], anchoredStart: Bool, anchoredEnd: Bool)

    /// The pattern a folded word of a term says.
    init(_ word: String) {
        guard word.contains("*") else { self = .word(word); return }
        let pieces = word.split(separator: "*").map(String.init)
        let anchoredStart = !word.hasPrefix("*"), anchoredEnd = !word.hasSuffix("*")
        switch (pieces.count, anchoredStart, anchoredEnd) {
        case (0, _, _): self = .any
        case (1, true, false): self = .prefix(pieces[0])
        case (1, false, true): self = .suffix(pieces[0])
        case (1, false, false): self = .infix(pieces[0])
        default: self = .pieces(pieces, anchoredStart: anchoredStart, anchoredEnd: anchoredEnd)
        }
    }

    /// Whether the folded `word` fits the pattern.
    func matches(_ word: String) -> Bool {
        switch self {
        case .word(let whole): return word == whole
        case .any: return true
        case .prefix(let start): return word.hasPrefix(start)
        case .suffix(let end): return word.hasSuffix(end)
        case .infix(let inside): return word.contains(inside)
        case .pieces(let pieces, let anchoredStart, let anchoredEnd):
            var rest = Substring(word)
            for (index, piece) in pieces.enumerated() {
                if index == 0, anchoredStart {
                    guard rest.hasPrefix(piece) else { return false }
                    rest = rest.dropFirst(piece.count)
                } else if index == pieces.count - 1, anchoredEnd {
                    return rest.hasSuffix(piece)
                } else {
                    guard let found = rest.range(of: piece) else { return false }
                    rest = rest[found.upperBound...]
                }
            }
            return true
        }
    }
}
"""##)

    static let node = KitTemplate("Sources/{{name}}/Keywords/KeywordNode.swift", needs: [.keywords], text: ##"""
//  WHAT: One step of the keyword tree: the words that may come next, each leading to a further step, and the term
//        that ends here.
//  PIN:  A WORD IS LOOKED UP, NOT TRIED. A word with a star sits in the table its shape is found by (what it starts
//        with, ends with or holds), so a step with a thousand `spoil*`-like words still costs a few lookups a word;
//        only a star in the middle of a word (`c*t`) is tried one by one.

import Foundation

struct KeywordNode: Sendable {
    /// Whole words: `spoiler`.
    var words: [String: Int] = [:]
    /// `spoil*`, by what the word starts with.
    var prefixes: [String: Int] = [:]
    /// `*coin`, by what the word ends with.
    var suffixes: [String: Int] = [:]
    /// `*ware*`, by what the word holds.
    var infixes: [String: Int] = [:]
    /// `c*t` and other words with a star inside, tried one by one.
    var shapes: [(pattern: KeywordPattern, next: Int)] = []
    /// `*` alone: any one word.
    var anyWord: Int?
    /// The longest key of each table, in characters: no longer piece of a word is looked up.
    var longestPrefix = 0, longestSuffix = 0, longestInfix = 0
    /// The term that ends here: its place in the filter's list.
    var term: Int?

    /// The steps the folded `word` leads to from here.
    func next(after word: String) -> [Int] {
        var found: [Int] = []
        if let step = words[word] { found.append(step) }
        if let step = anyWord { found.append(step) }
        if prefixes.isEmpty && suffixes.isEmpty && infixes.isEmpty && shapes.isEmpty { return found }
        let characters = Array(word)
        let count = characters.count
        for length in stride(from: min(count, longestPrefix), through: 1, by: -1) {
            if let step = prefixes[String(characters[0..<length])] { found.append(step) }
        }
        for length in stride(from: min(count, longestSuffix), through: 1, by: -1) {
            if let step = suffixes[String(characters[(count - length)...])] { found.append(step) }
        }
        if !infixes.isEmpty {
            for start in 0..<count {
                for length in stride(from: min(count - start, longestInfix), through: 1, by: -1) {
                    if let step = infixes[String(characters[start..<(start + length)])], !found.contains(step) { found.append(step) }
                }
            }
        }
        for shape in shapes where shape.pattern.matches(word) { found.append(shape.next) }
        return found
    }
}
"""##)

    static let match = KitTemplate("Sources/{{name}}/Keywords/KeywordMatch.swift", needs: [.keywords], text: ##"""
//  WHAT: A term found in a text: the term as the list gives it, the words it matched as the text writes them, and
//        where they stand.

import Foundation

/// A term found in a text.
public struct KeywordMatch: Hashable, Sendable {
    /// The term as the list gives it: `spoil*`.
    public let term: String
    /// The words the term matched, as the text writes them: `Spoilers`.
    public let text: String
    /// Where those words stand in the text.
    public let range: Range<String.Index>

    public init(term: String, text: String, range: Range<String.Index>) {
        self.term = term
        self.text = text
        self.range = range
    }
}
"""##)

    static let filter = KitTemplate("Sources/{{name}}/Keywords/KeywordFilter.swift", needs: [.keywords], text: ##"""
//  WHAT: Words and phrases found in text in one pass: every term compiled once into a tree of words, then a text's
//        words walked against it. Case, accents and width never matter; a term matches whole words only (`ass` is
//        not in `class`); `*` stands for any letters inside a word (`spoil*`, `*coin`) or, alone, for any one word
//        of a phrase (`free * money`); and a match says which term it was and where.
//  PIN:  ONE PASS, NOT A LOOP OF EXPRESSIONS. Thousands of terms share one tree, and a text's words are each looked
//        up in it, so a longer list costs memory, not time a text.
//  PIN:  THE LONGEST TERM WINS. Where several terms start at one word, the one that covers the most words is the
//        match (`spoiler alert` over `spoiler`), and of equals, the one listed first.

import Foundation

/// A list of words and phrases, compiled once to be found in any number of texts.
public struct KeywordFilter: Sendable {
    /// The terms that can match, in the order they were given.
    public let terms: [String]
    /// The terms with no word in them (`!!!`, `*`), which can never match.
    public let ignored: [String]
    private let nodes: [KeywordNode]

    /// Compiles `terms`: words, phrases, and words with `*` for any letters.
    public init(_ terms: some Sequence<String>) {
        var nodes = [KeywordNode()]
        var kept: [String] = [], ignored: [String] = []
        for term in terms {
            let patterns = KeywordTokenizer.tokens(in: term, wildcards: true).map { KeywordPattern($0.folded) }
            guard patterns.contains(where: { $0 != .any }) else { ignored.append(term); continue }
            var node = 0
            for pattern in patterns { node = Self.step(from: node, by: pattern, in: &nodes) }
            if nodes[node].term == nil { nodes[node].term = kept.count }
            kept.append(term)
        }
        self.terms = kept
        self.ignored = ignored
        self.nodes = nodes
    }

    /// Whether no term can match.
    public var isEmpty: Bool { terms.isEmpty }

    /// The first term found in `text`: the longest of those that start at the earliest word.
    public func firstMatch(in text: String) -> KeywordMatch? {
        guard !isEmpty else { return nil }
        let words = KeywordTokenizer.tokens(in: text)
        for start in words.indices {
            if let found = longest(from: start, in: words) { return match(found.term, from: start, to: found.end, of: words, in: text) }
        }
        return nil
    }

    /// Every term found in `text`, left to right, none overlapping another.
    public func matches(in text: String) -> [KeywordMatch] {
        guard !isEmpty else { return [] }
        let words = KeywordTokenizer.tokens(in: text)
        var found: [KeywordMatch] = []
        var start = 0
        while start < words.count {
            if let longest = longest(from: start, in: words) {
                found.append(match(longest.term, from: start, to: longest.end, of: words, in: text))
                start = longest.end + 1
            } else {
                start += 1
            }
        }
        return found
    }

    /// `text` with the letters and digits of every match masked (`•••• alert!`), its spaces and punctuation kept.
    public func redacting(_ text: String, with mask: Character = "•") -> String {
        let found = matches(in: text)
        guard !found.isEmpty else { return text }
        var result = ""
        var cursor = text.startIndex
        for match in found {
            result += text[cursor..<match.range.lowerBound]
            for character in text[match.range] {
                result.append(KeywordTokenizer.isWordCharacter(character) ? mask : character)
            }
            cursor = match.range.upperBound
        }
        result += text[cursor...]
        return result
    }

    /// Whether `term` has a word to match: not empty, and not only punctuation or stars.
    static func canMatch(_ term: String) -> Bool {
        KeywordTokenizer.tokens(in: term, wildcards: true).contains { KeywordPattern($0.folded) != .any }
    }

    /// `term` as the filter compares it, so `Spoil*  ALERT` and `spoil* alert` are one term.
    static func key(for term: String) -> String {
        KeywordTokenizer.tokens(in: term, wildcards: true).map(\.folded).joined(separator: " ")
    }

    // MARK: - The tree

    private static func step(from node: Int, by pattern: KeywordPattern, in nodes: inout [KeywordNode]) -> Int {
        let next = nodes.count
        switch pattern {
        case .word(let word):
            if let known = nodes[node].words[word] { return known }
            nodes[node].words[word] = next
        case .any:
            if let known = nodes[node].anyWord { return known }
            nodes[node].anyWord = next
        case .prefix(let start):
            if let known = nodes[node].prefixes[start] { return known }
            nodes[node].prefixes[start] = next
            nodes[node].longestPrefix = max(nodes[node].longestPrefix, start.count)
        case .suffix(let end):
            if let known = nodes[node].suffixes[end] { return known }
            nodes[node].suffixes[end] = next
            nodes[node].longestSuffix = max(nodes[node].longestSuffix, end.count)
        case .infix(let inside):
            if let known = nodes[node].infixes[inside] { return known }
            nodes[node].infixes[inside] = next
            nodes[node].longestInfix = max(nodes[node].longestInfix, inside.count)
        case .pieces:
            if let known = nodes[node].shapes.first(where: { $0.pattern == pattern }) { return known.next }
            nodes[node].shapes.append((pattern, next))
        }
        nodes.append(KeywordNode())
        return next
    }

    /// The term that covers the most words from `start`, and the last word it covers.
    private func longest(from start: Int, in words: [KeywordToken]) -> (term: Int, end: Int)? {
        var best: (term: Int, end: Int)?
        var pending = [(node: 0, word: start)]
        while let (node, word) = pending.popLast() {
            for next in nodes[node].next(after: words[word].folded) {
                if let term = nodes[next].term, Self.isLonger(term, ending: word, than: best) { best = (term, word) }
                if word + 1 < words.count { pending.append((next, word + 1)) }
            }
        }
        return best
    }

    /// Whether `term`, ending at word `end`, covers more words than `best`, or as many and is listed first.
    private static func isLonger(_ term: Int, ending end: Int, than best: (term: Int, end: Int)?) -> Bool {
        guard let best else { return true }
        return end > best.end || (end == best.end && term < best.term)
    }

    private func match(_ term: Int, from start: Int, to end: Int, of words: [KeywordToken], in text: String) -> KeywordMatch {
        let range = words[start].range.lowerBound..<words[end].range.upperBound
        return KeywordMatch(term: terms[term], text: String(text[range]), range: range)
    }
}
"""##)

    static let rule = KitTemplate("Sources/{{name}}/Keywords/KeywordRule.swift", needs: [.keywords], text: ##"""
//  WHAT: A term a policy filters: the word or phrase, whether it is on, and the text fields it looks in.
//  PIN:  A FIELD LEFT OUT DECODES AS ITS DEFAULT. A rule saved before a field existed still loads.

import Foundation

/// A term a policy filters, whether it is on, and the fields it looks in.
public struct KeywordRule: Codable, Sendable, Hashable, Identifiable {
    /// The word or phrase: `spoiler`, `buy now`, `crypto*`.
    public var term: String
    /// Whether the term is filtered.
    public var isEnabled: Bool
    /// The text fields it looks in (`title`, `body`); empty: every field.
    public var fields: Set<String>

    public var id: String { term }

    public init(_ term: String, isEnabled: Bool = true, fields: Set<String> = []) {
        self.term = term
        self.isEnabled = isEnabled
        self.fields = fields
    }

    private enum CodingKeys: String, CodingKey {
        case term, isEnabled, fields
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        term = try container.decode(String.self, forKey: .term)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        fields = try container.decodeIfPresent(Set<String>.self, forKey: .fields) ?? []
    }
}
"""##)

    static let scope = KitTemplate("Sources/{{name}}/Keywords/KeywordScope.swift", needs: [.keywords], text: ##"""
//  WHAT: A policy's enabled terms grouped by the fields they look in, each group compiled once: what the moderator
//        matches a text field against.

import Foundation

struct KeywordScope: Sendable {
    /// The fields the group looks in; empty: every field.
    let fields: Set<String>
    let filter: KeywordFilter

    func applies(to field: String) -> Bool { fields.isEmpty || fields.contains(field) }

    /// The enabled rules of `rules`, a group for each set of fields, in the order the sets first appear.
    static func scopes(for rules: [KeywordRule]) -> [KeywordScope] {
        var terms: [Set<String>: [String]] = [:]
        var order: [Set<String>] = []
        for rule in rules where rule.isEnabled {
            if terms[rule.fields] == nil { order.append(rule.fields) }
            terms[rule.fields, default: []].append(rule.term)
        }
        return order.map { KeywordScope(fields: $0, filter: KeywordFilter(terms[$0] ?? [])) }
    }
}
"""##)
}

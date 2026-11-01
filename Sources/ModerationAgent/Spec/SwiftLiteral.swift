//  WHAT: Values written into Swift source as literals: a string with its quotes and escapes, a Double.

import Foundation

enum SwiftLiteral {
    /// `text` as a Swift string literal, quotes included: `"say \"hi\""`.
    static func string(_ text: String) -> String {
        var out = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 || scalar.value == 0x7F {
                    out += "\\u{\(String(scalar.value, radix: 16))}"
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out + "\""
    }

    /// `value` as a Swift `Double` literal: `0.8`, `1.0`.
    static func double(_ value: Double) -> String {
        let text = String(value)
        return text.contains(".") || text.contains("e") ? text : text + ".0"
    }

    /// `terms` as the body of a `[String]` literal, a few to a line, for a declaration indented by `indent`:
    /// `[]`, or `[` and lines of terms and `]`.
    static func stringArray(_ terms: [String], indent: String, width: Int = 112) -> String {
        guard !terms.isEmpty else { return "[]" }
        var lines: [String] = []
        var line = ""
        for literal in terms.map(string) {
            let piece = literal + ","
            if !line.isEmpty, indent.count + 4 + line.count + 1 + piece.count > width {
                lines.append(line)
                line = ""
            }
            line += line.isEmpty ? piece : " " + piece
        }
        lines.append(line)
        return "[\n" + lines.map { indent + "    " + $0 }.joined(separator: "\n") + "\n" + indent + "]"
    }
}

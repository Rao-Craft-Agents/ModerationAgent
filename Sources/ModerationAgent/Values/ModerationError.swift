import Foundation

/// What a call can say instead of writing.
public enum ModerationError: Error, Equatable, CustomStringConvertible {
    /// What the call asks for that cannot be done: every reason, so all are fixed in one call.
    case refused([String])

    public var description: String {
        switch self {
        case .refused(let reasons) where reasons.count == 1:
            return "nothing was written: \(reasons[0])"
        case .refused(let reasons):
            return "\(reasons.count) things stop this call, so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}

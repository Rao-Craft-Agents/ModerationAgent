import Foundation

/// What a run says as it goes.
public enum ModerationFrame: Sendable {
    /// The call was read: how many files the package has, and where it is linked.
    case planned(files: Int, links: [String])
    /// The files are written.
    case written(ModerationResult)

    public var result: ModerationResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}

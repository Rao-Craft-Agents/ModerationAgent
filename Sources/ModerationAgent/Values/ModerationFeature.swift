import Foundation

/// A part of the moderation package a call may leave out.
public enum ModerationFeature: String, Codable, Sendable, CaseIterable {
    /// The keyword filter: words, phrases and `*` wildcards, matched in one pass.
    case keywords
    /// The image-safety gate: a Core ML classifier the app provides, run through Vision.
    case images
    /// The SwiftUI view modifier that blurs or folds content under its reason, until the person shows it.
    case overlay
    /// The SwiftUI editor of the keyword list; it needs `keywords`.
    case editor
}

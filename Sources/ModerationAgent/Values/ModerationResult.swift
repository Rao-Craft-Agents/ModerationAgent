import Foundation

/// What a call answers: the files written, as absolute paths, and what they hold.
public struct ModerationResult: Codable, Sendable, Equatable {
    /// The package's manifest, `Package.swift`.
    public var path: String?
    /// Every file written: the package's, and a project or manifest the package was linked into.
    public var paths: [String]
    /// The package's name: its module, product and folder name.
    public var package: String
    /// The package's folder, relative to the project.
    public var folder: String
    /// What the package holds, of keywords, images, overlay and editor.
    public var features: [String]
    /// Where the package was linked: `Recipes.xcodeproj (Recipes-iOS, Recipes-macOS)`, `Package.swift (Recipes)`.
    public var linked: [String]
    /// Files an earlier call wrote that this one left out, removed.
    public var removed: [String]
    /// One sentence each: what the call did beside writing, or left out, and why.
    public var notes: [String]

    public init(path: String?, paths: [String], package: String, folder: String, features: [String], linked: [String],
                removed: [String], notes: [String]) {
        self.path = path; self.paths = paths; self.package = package; self.folder = folder; self.features = features
        self.linked = linked; self.removed = removed; self.notes = notes
    }
}

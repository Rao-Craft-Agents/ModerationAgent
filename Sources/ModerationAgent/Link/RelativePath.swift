//  WHAT: The path from one folder to another, as a project or a manifest names a package: `Packages/ModerationKit`,
//        or `../Shared/ModerationKit` when the package lies beside the project rather than inside it.

import Foundation

enum RelativePath {
    /// The path from the folder `base` to `target`, both absolute.
    static func from(_ base: URL, to target: URL) -> String {
        let from = AgentFiles.resolvingParents(base.path).split(separator: "/")
        let to = AgentFiles.resolvingParents(target.path).split(separator: "/")
        var shared = 0
        while shared < min(from.count, to.count), from[shared] == to[shared] { shared += 1 }
        let parts = Array(repeating: "..", count: from.count - shared) + to[shared...].map(String.init)
        return parts.isEmpty ? "." : parts.joined(separator: "/")
    }
}

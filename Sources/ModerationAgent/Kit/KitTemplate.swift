//  WHAT: One file of the generated package: where it goes, the parts of the package it belongs to, and its text.

import Foundation

struct KitTemplate: Sendable {
    /// Where the file goes in the package; `{{name}}` is the package's name.
    let path: String
    /// The parts it needs: it is written only when the call has every one.
    let needs: Set<ModerationFeature>
    /// The parts it stands in for the lack of: it is written only when the call has none of them.
    let lacks: Set<ModerationFeature>
    /// The file, with `{{value}}` placeholders and `{{#part}}`/`{{^part}}` sections (`TemplateRenderer`).
    let text: String

    init(_ path: String, needs: Set<ModerationFeature> = [], lacks: Set<ModerationFeature> = [], text: String) {
        self.path = path
        self.needs = needs
        self.lacks = lacks
        self.text = text
    }

    /// Whether the file belongs to a package with `features`.
    func belongs(to features: Set<ModerationFeature>) -> Bool {
        needs.isSubset(of: features) && lacks.isDisjoint(with: features)
    }
}

//  WHAT: The generated package's files for a spec: every template that belongs to the call's parts, rendered with
//        the package's name, the starter terms, the unsafe label, the threshold and the model URL.
//  PIN:  THE SAME CALL MAKES THE SAME FILES. Nothing is asked of a model; every file comes from a template.

import Foundation

struct KitEmitter {
    let spec: ModerationSpec

    /// The files, by their path in the package, in the catalog's order.
    func files() throws -> [(path: String, text: String)] {
        let values = self.values
        let sections = self.sections
        return try KitCatalog.all.filter { $0.belongs(to: spec.features) }.map { template in
            let text = try TemplateRenderer.render(template.text, values: values, sections: sections)
            return (path(of: template), text.hasSuffix("\n") ? text : text + "\n")
        }
    }

    /// The paths of the catalog's files this call does not write: what an earlier call with other parts wrote.
    func leftOut() -> [String] {
        let written = Set(KitCatalog.all.filter { $0.belongs(to: spec.features) }.map(path(of:)))
        var seen: Set<String> = []
        return KitCatalog.all.map(path(of:)).filter { !written.contains($0) && seen.insert($0).inserted }
    }

    func path(of template: KitTemplate) -> String {
        template.path.replacingOccurrences(of: "{{name}}", with: spec.name)
    }

    var sections: Set<String> {
        var on = Set(spec.features.map(\.rawValue))
        if spec.modelURL != nil { on.insert("modelURL") }
        if !spec.terms.isEmpty { on.insert("terms") }
        return on
    }

    var values: [String: String] {
        [
            "name": spec.name,
            "labelLiteral": SwiftLiteral.string(spec.label),
            "labelText": spec.label.replacingOccurrences(of: "`", with: "'"),
            "threshold": SwiftLiteral.double(spec.threshold),
            "modelURLLiteral": SwiftLiteral.string(spec.modelURL?.absoluteString ?? ""),
            "modelURLText": spec.modelURL?.absoluteString ?? "",
            "starterTerms": SwiftLiteral.stringArray(spec.terms, indent: "    "),
        ]
    }
}

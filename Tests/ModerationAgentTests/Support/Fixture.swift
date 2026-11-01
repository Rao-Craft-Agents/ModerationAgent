import Foundation
@testable import ModerationAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("moderation-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// What a recipe app filters from the first launch.
    static let starterTerms = ["spoiler", "store-bought", "crypto*"]

    /// Every set of parts a call can ask for: keywords or images, each with or without the overlay and the editor.
    static let featureSets: [Set<ModerationFeature>] = {
        var sets: [Set<ModerationFeature>] = []
        for keywords in [false, true] {
            for images in [false, true] where keywords || images {
                for overlay in [false, true] {
                    for editor in [false, true] where keywords || !editor {
                        var set: Set<ModerationFeature> = []
                        if keywords { set.insert(.keywords) }
                        if images { set.insert(.images) }
                        if overlay { set.insert(.overlay) }
                        if editor { set.insert(.editor) }
                        sets.append(set)
                    }
                }
            }
        }
        return sets
    }()

    /// The call's whole run, as `run` makes it, against `folder`.
    static func write(_ input: ModerationAgent.Input, in folder: URL) throws -> ModerationResult {
        var input = input
        input.directory = folder.path
        return try ModerationAgent.write(input, note: { _ in }, yield: { _ in })
    }

    /// A 357-byte image classifier made for these tests: bright images are `NSFW`, dark ones `SFW`. It stands in for
    /// the model an app would provide, so the package's Core ML gate runs end to end.
    static let brightnessModel = Data(base64Encoded: "CAEShQEKEQoFaW1hZ2UaCCIGCAgQCBgUUg0KBXByb2JzGgQyAhIAUhAKCmNsYXNzTGFiZWwaAhoAWgpjbGFzc0xhYmVsYgVwcm9ic6IGOwo5QSB0ZXN0IGNsYXNzaWZpZXI6IGJyaWdodCBpbWFnZXMgYXJlIE5TRlcsIGRhcmsgb25lcyBTRlcumhnXAQoyCgRwb29sEgVpbWFnZRoGcG9vbGVkwgcaCAFSAggIogECCAjyAQYKBFIAUgCQAwHgAwEKFwoEZmxhdBIGcG9vbGVkGgRmbGF06hIACkUKAmZjEgRmbGF0GgZsb2dpdHPiCDAIAxACUAGiARoKGAAAAMAAAADAAAAAwAAAAEAAAABAAAAAQKoBCgoIAABAQAAAQMAKGwoHc29mdG1heBIGbG9naXRzGgVwcm9ic/oKABIOCgVpbWFnZVIFVYGAgDuiBgsKA1NGVwoETlNGV8IMBXByb2Jz")!
}

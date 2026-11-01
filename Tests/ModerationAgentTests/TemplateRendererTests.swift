import Foundation
import XCTest
@testable import ModerationAgent

/// The templates' little language, and the literals values are written as.
final class TemplateRendererTests: XCTestCase {
    func testSectionsKeepOrDropTheirLines() throws {
        let template = "a\n{{#on}}\nb {{name}}\n{{^off}}\nc\n{{/off}}\n{{/on}}\n{{#off}}\nd\n{{/off}}\ne"
        XCTAssertEqual(try TemplateRenderer.render(template, values: ["name": "Kit"], sections: ["on"]), "a\nb Kit\nc\ne")
        XCTAssertEqual(try TemplateRenderer.render(template, values: ["name": "Kit"], sections: ["on", "off"]), "a\nb Kit\nd\ne")
        XCTAssertEqual(try TemplateRenderer.render(template, values: ["name": "Kit"], sections: []), "a\ne")
    }

    func testAFaultOfTheTemplateIsSaid() {
        let faults = ["{{#on}}\na": "never closed", "a\n{{/on}}": "closes no open section", "a {{#on}} b": "line of its own",
                      "{{unknown}}": "not a value"]
        for (template, reason) in faults {
            XCTAssertThrowsError(try TemplateRenderer.render(template, values: [:], sections: ["on"]), template) { error in
                XCTAssertTrue("\(error)".contains(reason), "\(template): \(error)")
            }
        }
    }

    func testEveryTemplateRendersWithEverySetOfParts() throws {
        for features in Fixture.featureSets {
            for modelURL in [nil, "https://models.example.com/food.mlmodel"] {
                var spec = ModerationSpec.read(.init(keywords: ["a"], modelURL: modelURL, features: Array(features), link: false),
                                               files: AgentFiles(directory: NSTemporaryDirectory())).spec
                spec.features = features
                XCTAssertNoThrow(try KitEmitter(spec: spec).files(), "\(features)")
            }
        }
    }

    func testLiterals() {
        XCTAssertEqual(SwiftLiteral.string(#"say "hi" \ now"#), #""say \"hi\" \\ now""#)
        XCTAssertEqual(SwiftLiteral.string("tab\there"), #""tab\there""#)
        XCTAssertEqual(SwiftLiteral.double(0.8), "0.8")
        XCTAssertEqual(SwiftLiteral.double(1), "1.0")
        XCTAssertEqual(SwiftLiteral.stringArray([], indent: "    "), "[]")
        let many = SwiftLiteral.stringArray((1...40).map { "term \($0)" }, indent: "    ")
        XCTAssertTrue(many.hasPrefix("[\n        \"term 1\", "))
        XCTAssertTrue(many.hasSuffix(",\n    ]"))
        XCTAssertTrue(many.split(separator: "\n").allSatisfy { $0.count <= 112 }, many)
    }
}

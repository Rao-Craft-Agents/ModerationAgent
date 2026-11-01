//  WHAT: A local Swift package linked into an Xcode project by editing `project.pbxproj` as text: the package's
//        reference (in the project's `packageReferences`), and for every application target a product dependency
//        and a build file in its Frameworks phase; a deployment target below what the package needs is raised.
//  PIN:  READ AS A PLIST, EDITED AS TEXT. What is there is read with PropertyListSerialization; what is added goes
//        in as lines where Xcode would put them, and every other byte stays as it was, so a diff shows the link and
//        nothing else.
//  PIN:  IDEMPOTENT. A second call finds the reference, the dependencies and the build files, and changes nothing.
//  PIN:  NEVER INSIDE A SYNCHRONIZED FOLDER. Every file under one joins the app targets, so a package there would
//        be compiled into the app; such a folder is refused before anything is written.

import Foundation

struct ProjectLinker {
    /// What linking did to one project.
    struct Outcome {
        /// The project file's new text; nil when it already linked the package.
        var text: String?
        /// The application targets that link the package.
        var targets: [String]
        var notes: [String]
    }

    /// The product the app targets link: the package's name.
    let product: String
    /// The package's folder, relative to the folder that holds the `.xcodeproj`.
    let packagePath: String
    /// The lowest versions the package builds for.
    var minimumMacOS = "14.0"
    var minimumIOS = "17.0"

    /// `pbxproj` with the package linked into every application target.
    func link(_ pbxproj: String, project: String) -> Outcome? {
        guard let graph = Graph(pbxproj) else { return nil }
        var text = PBXText(pbxproj)
        let appTargets = graph.applicationTargets
        guard !appTargets.isEmpty else {
            return Outcome(text: nil, targets: [], notes: ["\(project) has no application target, so the package was not linked into it."])
        }
        var notes: [String] = []
        let folderName = packagePath.split(separator: "/").last.map(String.init) ?? product

        // The package's reference, once, listed by the project.
        var reference = graph.objects.first { id, object in
            object["isa"] as? String == "XCLocalSwiftPackageReference"
                && Self.normalized(object["relativePath"] as? String ?? "") == Self.normalized(packagePath)
        }?.key
        let referenceComment = "XCLocalSwiftPackageReference \"\(folderName)\""
        if reference == nil {
            let id = ObjectID.fresh("\(project)|\(packagePath)|reference", avoiding: text)
            Self.addObject("""
                \t\t\(id) /* \(referenceComment) */ = {
                \t\t\tisa = XCLocalSwiftPackageReference;
                \t\t\trelativePath = \(Self.plistString(packagePath));
                \t\t};

                """, isa: "XCLocalSwiftPackageReference", to: &text)
            reference = id
        }
        guard let reference else { return nil }
        if !(graph.root["packageReferences"] as? [String] ?? []).contains(reference) {
            Self.addItem("\(reference) /* \(referenceComment) */", toList: "packageReferences", of: graph.rootID, in: &text)
        }

        var linked: [String] = []
        for (targetID, target) in appTargets {
            let name = target["name"] as? String ?? targetID
            linked.append(name)
            let dependencies = target["packageProductDependencies"] as? [String] ?? []
            var dependency = dependencies.first { id in
                graph.objects[id]?["isa"] as? String == "XCSwiftPackageProductDependency" && graph.objects[id]?["productName"] as? String == product
            }
            if dependency == nil {
                let id = ObjectID.fresh("\(project)|\(targetID)|\(product)|dependency", avoiding: text)
                Self.addObject("""
                    \t\t\(id) /* \(product) */ = {
                    \t\t\tisa = XCSwiftPackageProductDependency;
                    \t\t\tpackage = \(reference) /* \(referenceComment) */;
                    \t\t\tproductName = \(Self.plistString(product));
                    \t\t};

                    """, isa: "XCSwiftPackageProductDependency", to: &text)
                Self.addItem("\(id) /* \(product) */", toList: "packageProductDependencies", of: targetID, in: &text)
                dependency = id
            }
            guard let dependency else { continue }

            let phases = target["buildPhases"] as? [String] ?? []
            var frameworks = phases.first { graph.objects[$0]?["isa"] as? String == "PBXFrameworksBuildPhase" }
            if frameworks == nil {
                let id = ObjectID.fresh("\(project)|\(targetID)|frameworks", avoiding: text)
                Self.addObject("""
                    \t\t\(id) /* Frameworks */ = {
                    \t\t\tisa = PBXFrameworksBuildPhase;
                    \t\t\tbuildActionMask = 2147483647;
                    \t\t\tfiles = (
                    \t\t\t);
                    \t\t\trunOnlyForDeploymentPostprocessing = 0;
                    \t\t};

                    """, isa: "PBXFrameworksBuildPhase", to: &text)
                let sources = phases.first { graph.objects[$0]?["isa"] as? String == "PBXSourcesBuildPhase" }
                Self.addItem("\(id) /* Frameworks */", toList: "buildPhases", of: targetID, after: sources, in: &text)
                frameworks = id
            }
            guard let frameworks else { continue }
            let files = graph.objects[frameworks]?["files"] as? [String] ?? []
            let built = files.contains { graph.objects[$0]?["productRef"] as? String == dependency }
            if !built {
                let id = ObjectID.fresh("\(project)|\(targetID)|\(product)|build", avoiding: text)
                Self.addObject("\t\t\(id) /* \(product) in Frameworks */ = {isa = PBXBuildFile; productRef = \(dependency) /* \(product) */; };\n",
                               isa: "PBXBuildFile", to: &text)
                Self.addItem("\(id) /* \(product) in Frameworks */", toList: "files", of: frameworks, in: &text)
            }
        }

        notes += raiseDeploymentTargets(graph, appTargets: appTargets.map(\.id), in: &text)
        let changed = text.bytes != Array(pbxproj.utf8)
        return Outcome(text: changed ? text.text : nil, targets: linked, notes: notes)
    }

    /// The paths of `pbxproj`'s synchronized folders, relative to the folder that holds the `.xcodeproj`.
    static func synchronizedFolders(_ pbxproj: String) -> [String] {
        guard let graph = Graph(pbxproj), let main = graph.root["mainGroup"] as? String else { return [] }
        var found: [String] = []
        func walk(_ id: String, base: String) {
            guard let object = graph.objects[id] else { return }
            let isa = object["isa"] as? String
            guard isa == "PBXGroup" || isa == "PBXFileSystemSynchronizedRootGroup" else { return }
            var path = base
            if let own = object["path"] as? String {
                path = (object["sourceTree"] as? String) == "SOURCE_ROOT" ? own : (base.isEmpty ? own : base + "/" + own)
            }
            if isa == "PBXFileSystemSynchronizedRootGroup" { found.append(normalized(path)); return }
            for child in object["children"] as? [String] ?? [] { walk(child, base: path) }
        }
        walk(main, base: "")
        return found
    }

    // MARK: - Deployment targets

    /// Raises every macOS or iOS deployment target below the package's, in the app targets' configurations and the
    /// project's; a sentence for each raised.
    private func raiseDeploymentTargets(_ graph: Graph, appTargets: [String], in text: inout PBXText) -> [String] {
        var notes: [String] = []
        let lists = appTargets.compactMap { graph.objects[$0]?["buildConfigurationList"] as? String }
            + [graph.root["buildConfigurationList"] as? String].compactMap { $0 }
        let owners = Dictionary(appTargets.compactMap { id in (graph.objects[id]?["buildConfigurationList"] as? String).map { ($0, graph.objects[id]?["name"] as? String ?? id) } },
                                uniquingKeysWith: { first, _ in first })
        var raised: [String: (from: Set<String>, owners: [String])] = [:]
        for list in lists {
            for configuration in graph.objects[list]?["buildConfigurations"] as? [String] ?? [] {
                for (key, minimum) in [("MACOSX_DEPLOYMENT_TARGET", minimumMacOS), ("IPHONEOS_DEPLOYMENT_TARGET", minimumIOS)] {
                    guard let settings = graph.objects[configuration]?["buildSettings"] as? [String: Any],
                          let value = settings[key] as? String, Self.version(value, isBelow: minimum),
                          Self.replaceSetting(key, with: minimum, in: configuration, text: &text) else { continue }
                    let owner = owners[list] ?? "the project"
                    var entry = raised[key] ?? ([], [])
                    entry.from.insert(value)
                    if !entry.owners.contains(owner) { entry.owners.append(owner) }
                    raised[key] = entry
                }
            }
        }
        for (key, minimum) in [("MACOSX_DEPLOYMENT_TARGET", minimumMacOS), ("IPHONEOS_DEPLOYMENT_TARGET", minimumIOS)] {
            guard let entry = raised[key] else { continue }
            let platform = key.hasPrefix("MACOSX") ? "macOS" : "iOS"
            notes.append("The \(platform) deployment target of \(entry.owners.joined(separator: ", ")) was raised from \(entry.from.sorted().joined(separator: ", ")) to \(minimum), the lowest the package builds for.")
        }
        return notes
    }

    private static func replaceSetting(_ key: String, with value: String, in configuration: String, text: inout PBXText) -> Bool {
        guard let open = text.objectOpen(configuration),
              let settings = text.entries(ofDictionaryAt: open).first(where: { $0.key == "buildSettings" }),
              let entry = text.entries(ofDictionaryAt: settings.value.lowerBound).first(where: { $0.key == key }) else { return false }
        let quoted = text.string(entry.value).hasPrefix("\"")
        text.replace(entry.value, with: quoted ? "\"\(value)\"" : value)
        return true
    }

    /// Whether the version `value` (`13.0`, `16.4`, `13`) is below `minimum`.
    static func version(_ value: String, isBelow minimum: String) -> Bool {
        let parts = { (text: String) in text.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")).split(separator: ".").map { Int($0) ?? 0 } }
        let have = parts(value), need = parts(minimum)
        for index in 0..<max(have.count, need.count) {
            let a = index < have.count ? have[index] : 0, b = index < need.count ? need[index] : 0
            if a != b { return a < b }
        }
        return false
    }

    // MARK: - Editing

    /// Adds `block` (whole lines) to the section of `isa`, making the section where Xcode would when it is missing.
    static func addObject(_ block: String, isa: String, to text: inout PBXText) {
        if let end = text.offset(of: "/* End \(isa) section */") {
            text.insert(block, at: text.lineStart(of: end))
            return
        }
        let section = "/* Begin \(isa) section */\n" + block + "/* End \(isa) section */\n"
        var later: Int?
        var search = 0
        while let begin = text.bytes[search...].firstRange(of: Array("/* Begin ".utf8)) {
            let nameStart = begin.upperBound
            let nameEnd = text.bytes[nameStart...].firstIndex(of: UInt8(ascii: " ")) ?? nameStart
            if text.string(nameStart..<nameEnd) > isa { later = begin.lowerBound; break }
            search = begin.upperBound
        }
        if let later {
            text.insert(section + "\n", at: text.lineStart(of: later))
        } else if let objects = objectsClose(text) {
            text.insert("\n" + section, at: text.lineStart(of: objects))
        }
    }

    /// Adds `item` to the list `key` of object `id`: after the item `after` when it is listed, else at the end; the
    /// list is made, among the object's keys in Xcode's order, when it is missing.
    static func addItem(_ item: String, toList key: String, of id: String, after: String? = nil, in text: inout PBXText) {
        guard let open = text.objectOpen(id) else { return }
        let entries = text.entries(ofDictionaryAt: open)
        if let entry = entries.first(where: { $0.key == key }), text.bytes[entry.value.lowerBound] == UInt8(ascii: "(") {
            let close = entry.value.upperBound - 1
            let closeLine = text.lineStart(of: close)
            if text.isBlank(closeLine..<close) {
                let line = text.indentation(ofLineAt: closeLine) + "\t" + item + ",\n"
                if let after, let previous = text.items(ofListAt: entry.value.lowerBound).first(where: { $0.value == after }) {
                    text.insert(line, at: text.lineEnd(of: previous.range.lowerBound))
                } else {
                    text.insert(line, at: closeLine)
                }
            } else {
                text.insert(" \(item),", at: entry.value.lowerBound + 1)
            }
            return
        }
        let indent = entries.first.map { text.indentation(ofLineAt: $0.line) } ?? "\t\t\t"
        let lines = "\(indent)\(key) = (\n\(indent)\t\(item),\n\(indent));\n"
        if let next = entries.first(where: { $0.key != "isa" && $0.key > key }) {
            text.insert(lines, at: next.line)
        } else if let close = text.closing(from: open) {
            text.insert(lines, at: text.lineStart(of: close))
        }
    }

    /// The `}` that closes the file's `objects`.
    private static func objectsClose(_ text: PBXText) -> Int? {
        guard let root = text.bytes.firstIndex(of: UInt8(ascii: "{")),
              let objects = text.entries(ofDictionaryAt: root).first(where: { $0.key == "objects" }) else { return nil }
        return objects.value.upperBound - 1
    }

    /// `value` as the format writes it: bare when it can be, quoted otherwise.
    static func plistString(_ value: String) -> String {
        let bare = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$./-")
        if !value.isEmpty, value.unicodeScalars.allSatisfy(bare.contains), !value.contains("//") { return value }
        return "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    /// A relative path written one way: no `./`, no doubled or trailing slash.
    static func normalized(_ path: String) -> String {
        path.split(separator: "/").filter { $0 != "." }.joined(separator: "/")
    }
}

extension ProjectLinker {
    /// The project file read as a plist: its objects and its root.
    struct Graph {
        let objects: [String: [String: Any]]
        let rootID: String
        let root: [String: Any]

        init?(_ pbxproj: String) {
            guard let plist = try? PropertyListSerialization.propertyList(from: Data(pbxproj.utf8), format: nil) as? [String: Any],
                  let objects = plist["objects"] as? [String: [String: Any]],
                  let rootID = plist["rootObject"] as? String, let root = objects[rootID] else { return nil }
            self.objects = objects
            self.rootID = rootID
            self.root = root
        }

        /// The project's application targets, in its order.
        var applicationTargets: [(id: String, target: [String: Any])] {
            (root["targets"] as? [String] ?? []).compactMap { id in
                guard let target = objects[id], target["isa"] as? String == "PBXNativeTarget",
                      target["productType"] as? String == "com.apple.product-type.application" else { return nil }
                return (id, target)
            }
        }
    }
}

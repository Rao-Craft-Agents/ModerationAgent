//  WHAT: The generated package's image-safety gate: the protocol, the Core ML classifier the app provides, its download and cache, and the image loader.
//  PIN:  EDIT THE TEMPLATE, THEN BUILD IT. `MODERATION_BUILD=1 swift test` renders every set of parts and builds
//        and tests each package for real.

import Foundation

enum ImageTemplates {
    static let safety = KitTemplate("Sources/{{name}}/Images/ImageSafety.swift", needs: [.images], text: ##"""
//  WHAT: What screens an image: a score from 0 (safe) to 1 (certainly not). `CoreMLImageSafety` runs a classifier
//        the app provides; a test or a preview gives its own.

import CoreGraphics

/// Something that says how likely an image is to be unsafe.
public protocol ImageSafety: Sendable {
    /// How likely `image` is to be unsafe, from 0 to 1.
    func score(_ image: CGImage) async throws -> Double
}
"""##)

    static let error = KitTemplate("Sources/{{name}}/Images/ImageSafetyError.swift", needs: [.images], text: ##"""
//  WHAT: Why an image could not be screened: no model where one was named, a download the server refused, a model
//        that is not a classifier or has no such label, or an image that would not decode.

import Foundation

/// Why an image could not be screened.
public enum ImageSafetyError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The bundle holds no compiled model (`.mlmodelc`) by this name.
    case missingModel(String)
    /// The model's download answered with this HTTP status.
    case download(URL, status: Int)
    /// The model gave no classifications: it is not an image classifier.
    case notAClassifier
    /// The classifier has no such label; the labels it has.
    case unknownLabel(String, labels: [String])
    /// The image's bytes did not decode.
    case unreadableImage

    public var description: String {
        switch self {
        case .missingModel(let name): "the bundle holds no compiled model named \(name).mlmodelc"
        case .download(let url, let status): "downloading the model from \(url.absoluteString) answered \(status)"
        case .notAClassifier: "the model gave no classifications: it is not an image classifier"
        case .unknownLabel(let label, let labels): "the classifier has no label \(label); it has \(labels.joined(separator: ", "))"
        case .unreadableImage: "the image did not decode"
        }
    }
}
"""##)

    static let coreML = KitTemplate("Sources/{{name}}/Images/CoreMLImageSafety.swift", needs: [.images], text: ##"""
//  WHAT: Image safety from an image classifier the app provides, run through Vision: a compiled model in a bundle,
//        a compiled model on disk, or an `.mlmodel` downloaded once from a URL, compiled on the device and kept in
//        Application Support. An image's score is the classifier's confidence in the label that means unsafe.
//  PIN:  NO MODEL SHIPS HERE. A model's size and licence are the app's to choose; this package only runs one.
//  PIN:  THE MODEL IS MADE ONCE. Calls that arrive while it loads wait for that one load, and a load that failed
//        (offline, say) is tried again by the next call.

import CoreGraphics
import Foundation

/// Screens images with an image classifier the app provides, through Core ML and Vision.
public actor CoreMLImageSafety: ImageSafety {
    /// Where the classifier comes from.
    public enum Source: Sendable, Hashable {
        /// A compiled model in a bundle, by name: an `.mlmodel` added to an app target is compiled into the app's
        /// bundle as `Name.mlmodelc`.
        case bundled(String, in: Bundle = .main)
        /// A compiled model (`.mlmodelc`) at a file URL.
        case compiled(URL)
        /// An `.mlmodel` at a URL (https, or a file the app wrote), downloaded once, compiled on the device and kept.
        case remote(URL)
    }

    /// Where the classifier comes from.
    public nonisolated let source: Source
    /// The classifier's label that means unsafe: its confidence is an image's score.
    public nonisolated let unsafeLabel: String
    private let folder: URL?
    private var classifier: VisionClassifier?
    private var loading: Task<VisionClassifier, any Error>?

    /// - Parameters:
    ///   - source: where the classifier comes from.
    ///   - unsafeLabel: the label that means unsafe, matched without regard to case.
    ///   - folder: where a downloaded model is kept; Application Support when nil.
    public init(source: Source, unsafeLabel: String = {{labelLiteral}}, folder: URL? = nil) {
        self.source = source
        self.unsafeLabel = unsafeLabel
        self.folder = folder
    }

{{#modelURL}}
    /// The `.mlmodel` this app downloads when it names no other.
    public static let defaultModelURL = URL(string: {{modelURLLiteral}})!

    /// Screens with the model at `defaultModelURL`, downloaded and compiled on first use.
    public init(unsafeLabel: String = {{labelLiteral}}) {
        self.init(source: .remote(Self.defaultModelURL), unsafeLabel: unsafeLabel)
    }
{{/modelURL}}

    /// Loads the classifier now (downloading and compiling it if it must), so the first image is not kept waiting.
    public func prepare() async throws {
        _ = try await loadedClassifier()
    }

    /// The classifier's confidence in `unsafeLabel` for `image`, from 0 to 1; the first call loads the classifier.
    public func score(_ image: CGImage) async throws -> Double {
        try await loadedClassifier().confidence(in: unsafeLabel, for: image)
    }

    private func loadedClassifier() async throws -> VisionClassifier {
        if let classifier { return classifier }
        if let loading { return try await loading.value }
        let source = source, folder = folder
        let task = Task { try await Self.load(source, folder: folder) }
        loading = task
        defer { loading = nil }
        let loaded = try await task.value
        classifier = loaded
        return loaded
    }

    private static func load(_ source: Source, folder: URL?) async throws -> VisionClassifier {
        switch source {
        case .bundled(let name, let bundle):
            guard let url = bundle.url(forResource: name, withExtension: "mlmodelc") else { throw ImageSafetyError.missingModel(name) }
            return try await VisionClassifier.load(compiledModel: url)
        case .compiled(let url):
            return try await VisionClassifier.load(compiledModel: url)
        case .remote(let url):
            let compiled = try await ModelStore.compiledModel(from: url, in: try folder ?? ModelStore.defaultFolder())
            return try await VisionClassifier.load(compiledModel: compiled)
        }
    }
}
"""##)

    static let classifier = KitTemplate("Sources/{{name}}/Images/VisionClassifier.swift", needs: [.images], text: ##"""
//  WHAT: A loaded image classifier and the queue it runs on: the score of one label for an image, through Vision.
//  PIN:  CONFINED TO ITS QUEUE. Vision's model is not marked Sendable. It is only ever used on `queue`, which is
//        serial, one request at a time, so handing the box between tasks is safe: `@unchecked Sendable` says
//        exactly that and nothing more.
//  PIN:  NEVER ON A SHARED THREAD. A request blocks while the model runs, so it runs on `queue`, and the caller
//        awaits it without holding a thread of the cooperative pool or the main thread.

import CoreGraphics
import CoreML
import Foundation
import Vision

final class VisionClassifier: @unchecked Sendable {
    private let model: VNCoreMLModel
    private let queue = DispatchQueue(label: "{{name}}.VisionClassifier", qos: .userInitiated)

    private init(_ model: VNCoreMLModel) { self.model = model }

    /// The classifier in the compiled model at `url`.
    static func load(compiledModel url: URL) async throws -> VisionClassifier {
        let model = try await MLModel.load(contentsOf: url, configuration: MLModelConfiguration())
        return VisionClassifier(try VNCoreMLModel(for: model))
    }

    /// The classifier's confidence in `label` for `image`, from 0 to 1.
    func confidence(in label: String, for image: CGImage) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try self.classify(image, label: label) })
            }
        }
    }

    private func classify(_ image: CGImage, label: String) throws -> Double {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .scaleFill
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        let observations = request.results as? [VNClassificationObservation] ?? []
        guard !observations.isEmpty else { throw ImageSafetyError.notAClassifier }
        guard let match = observations.first(where: { $0.identifier.caseInsensitiveCompare(label) == .orderedSame }) else {
            throw ImageSafetyError.unknownLabel(label, labels: observations.map(\.identifier))
        }
        return Double(match.confidence)
    }
}
"""##)

    static let store = KitTemplate("Sources/{{name}}/Images/ModelStore.swift", needs: [.images], text: ##"""
//  WHAT: An `.mlmodel` at a URL made into a compiled model on disk once: downloaded, compiled by Core ML on the
//        device, and kept under Application Support by a name the URL decides, so later launches load it with no
//        network.
//  PIN:  A FINISHED MODEL OR NONE. The compiled model is moved into place only after the compile succeeded, so a
//        download cut off half-way is never taken for a model, and the next call simply tries again.
//  PIN:  NOT BACKED UP. A model the app can download again is excluded from iCloud backups, as Apple asks.

import CoreML
import Foundation

enum ModelStore {
    /// The compiled model for `url` in `folder`: the one kept there, or one downloaded and compiled into it.
    static func compiledModel(from url: URL, in folder: URL) async throws -> URL {
        let manager = FileManager.default
        let name = cacheName(for: url)
        let destination = folder.appendingPathComponent(name + ".mlmodelc", isDirectory: true)
        if manager.fileExists(atPath: destination.path) { return destination }
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)

        // Core ML compiles a model by its extension, so the download is named `.mlmodel` first.
        let model = folder.appendingPathComponent(name + ".mlmodel")
        try? manager.removeItem(at: model)
        if url.isFileURL {
            try manager.copyItem(at: url, to: model)
        } else {
            let (download, response) = try await URLSession.shared.download(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                try? manager.removeItem(at: download)
                throw ImageSafetyError.download(url, status: http.statusCode)
            }
            try manager.moveItem(at: download, to: model)
        }
        defer { try? manager.removeItem(at: model) }

        let compiled = try await MLModel.compileModel(at: model)
        if manager.fileExists(atPath: destination.path) {
            // Another load finished first: keep its model.
            try? manager.removeItem(at: compiled)
            return destination
        }
        try manager.moveItem(at: compiled, to: destination)
        var kept = destination
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? kept.setResourceValues(values)
        return destination
    }

    /// `nsfw-model-1b3e9c0a77f2d415`: the file's name and a hash of the whole URL, so two URLs never share a model.
    static func cacheName(for url: URL) -> String {
        let base = url.deletingPathExtension().lastPathComponent
        let kept = base.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" }
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in url.absoluteString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        let stem = kept.isEmpty ? "model" : String(String.UnicodeScalarView(kept.prefix(48)))
        return stem + "-" + String(hash, radix: 16)
    }

    /// Application Support/<the app>/{{name}}/Models: the app's own on iOS and in a sandbox, and named by the
    /// app's bundle identifier on an unsandboxed Mac, where Application Support is shared.
    static func defaultFolder() throws -> URL {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return support
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "{{name}}", isDirectory: true)
            .appendingPathComponent("{{name}}", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }
}
"""##)

    static let loader = KitTemplate("Sources/{{name}}/Images/ImageLoader.swift", needs: [.images], text: ##"""
//  WHAT: An image to screen made into a small CGImage: fetched with URLSession, or read from its bytes, and decoded
//        by ImageIO straight to a thumbnail, so a 4,000-pixel photo costs the memory of a 512-pixel one.
//  PIN:  A CLASSIFIER SEES A FEW HUNDRED PIXELS. Vision scales every image to the model's input (often 224), so
//        decoding more than `maxPixels` would only cost memory and time.

import CoreGraphics
import Foundation
import ImageIO

struct ImageLoader: Sendable {
    let session: URLSession
    /// The longest side an image is decoded to.
    var maxPixels = 512

    /// `image` loaded and decoded.
    func image(_ image: ModeratedImage) async throws -> CGImage {
        switch image {
        case .image(let decoded):
            return decoded
        case .data(let data):
            return try Self.thumbnail(of: data, maxPixels: maxPixels)
        case .url(let url):
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            return try Self.thumbnail(of: data, maxPixels: maxPixels)
        }
    }

    /// The first frame of `data`, upright, its longest side at most `maxPixels`.
    static func thumbnail(of data: Data, maxPixels: Int) throws -> CGImage {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        let thumbnail = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnail) else {
            throw ImageSafetyError.unreadableImage
        }
        return image
    }
}
"""##)
}

import Foundation

/// A command run to the end, its output and errors read together.
enum Shell {
    static func run(_ arguments: [String], in folder: URL? = nil) throws -> (status: Int32, log: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        if let folder { process.currentDirectoryURL = folder }
        let out = Pipe()
        process.standardOutput = out
        process.standardError = out
        process.standardInput = FileHandle.nullDevice
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// The last lines of `log` that say what failed, for an assertion's message.
    static func tail(_ log: String, lines: Int = 40) -> String {
        let errors = log.split(separator: "\n").filter { $0.contains("error:") || $0.contains("FAILED") || $0.contains("failed") }
        return (errors.isEmpty ? log.split(separator: "\n").suffix(lines) : errors.prefix(lines)).joined(separator: "\n")
    }
}

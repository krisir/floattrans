import Foundation

enum DiagnosticLog {
    static var isFileLoggingEnabled: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static func write(_ message: String) {
        #if DEBUG
        fileQueue.async { append(message) }
        #endif
    }

    #if DEBUG
    private static let fileQueue = DispatchQueue(label: "com.liveenglish.diagnostic-log")
    private static let url = URL(fileURLWithPath: "/tmp/liveenglish-debug.log")
    private static let maxBytes = 512_000

    private static func append(_ message: String) {
        let line = "\(ISO8601DateFormatter().string(from: .now)) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        let manager = FileManager.default
        if let attributes = try? manager.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? NSNumber,
            size.intValue > maxBytes
        {
            try? manager.removeItem(at: url)
        }
        if manager.fileExists(atPath: url.path), let handle = try? FileHandle(forWritingTo: url) {
            _ = try? handle.seekToEnd()
            _ = try? handle.write(contentsOf: data)
            _ = try? handle.close()
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
    #endif
}

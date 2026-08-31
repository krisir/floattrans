import Foundation

enum DiagnosticLog {
    private static let url = URL(fileURLWithPath: "/tmp/liveenglish-debug.log")
    static func write(_ message: String) {
        let line = "\(ISO8601DateFormatter().string(from: .now)) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: url.path), let handle = try? FileHandle(forWritingTo: url) {
            _ = try? handle.seekToEnd()
            _ = try? handle.write(contentsOf: data)
            _ = try? handle.close()
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
}

import Foundation
import Translation

public enum Language: Sendable { case chinese, english }
public struct TextSnapshot: Sendable { public let pid: pid_t; public let bundleIdentifier: String?; public let text: String; public let selectedRange: NSRange?; public let timestamp: Date
    public init(pid: pid_t, bundleIdentifier: String?, text: String, selectedRange: NSRange?, timestamp: Date = .now) { self.pid = pid; self.bundleIdentifier = bundleIdentifier; self.text = text; self.selectedRange = selectedRange; self.timestamp = timestamp }
}

public struct SentenceExtractor: Sendable {
    public init() {}
    public func extract(from snapshot: TextSnapshot, maxLength: Int = 300) -> String {
        let text = snapshot.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "" }
        let cursor = snapshot.selectedRange.map { min(max($0.location, 0), text.utf16.count) } ?? text.utf16.count
        let chars = Array(text)
        var cursorIndex = min(cursor, chars.count)
        let boundaries: Set<Character> = ["。", "？", "！", "\n", ".", "?", "!", "；", ";"]
        // Accessibility usually reports the caret after the newly typed punctuation.
        // Move it just before that boundary so the completed sentence is translated.
        if cursorIndex > 0, cursorIndex <= chars.count, boundaries.contains(chars[cursorIndex - 1]) { cursorIndex -= 1 }
        var start = cursorIndex
        while start > 0 && !boundaries.contains(chars[start - 1]) { start -= 1 }
        var end = cursorIndex
        while end < chars.count && !boundaries.contains(chars[end]) { end += 1 }
        var result = String(chars[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        if result.count > maxLength { result = String(result.suffix(maxLength)) }
        return result
    }
}

public struct ChineseTextDetector: Sendable {
    public init() {}
    public func containsChinese(_ text: String) -> Bool { text.unicodeScalars.contains { (0x4E00...0x9FFF).contains(Int($0.value)) } }
}

public actor TranslationCoordinator {
    private let engine: any TranslationEngine
    private var generation = 0
    private var task: Task<String, Error>?
    private var cache: [String: String] = [:]
    public init(engine: any TranslationEngine) { self.engine = engine }
    public func translate(_ text: String) async -> String? {
        let key = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        generation += 1; let current = generation
        task?.cancel()
        if let cached = cache[key] { return cached }
        let newTask = Task { try await engine.translate(key, from: .chinese, to: .english) }
        task = newTask
        do { let value = try await newTask.value; guard current == generation, !Task.isCancelled else { return nil }; cache[key] = value; return value }
        catch { DiagnosticLog.write("translation error type=\(String(reflecting: error))"); return nil }
    }
    public func cancel() { generation += 1; task?.cancel(); task = nil }
}

public protocol TranslationEngine: Sendable { func translate(_ text: String, from: Language, to: Language) async throws -> String }

public struct DemoTranslationEngine: TranslationEngine {
    public init() {}
    public func translate(_ text: String, from: Language, to: Language) async throws -> String {
        // Replace this adapter with Apple Translation when the deployment SDK exposes Translation.framework.
        let known: [String: String] = ["我晚点看一下": "I'll take a look later.", "明天继续": "I'll continue tomorrow.", "你好": "Hello."]
        return known[text] ?? "(English translation) " + text
    }
}

@available(macOS 26.0, *)
public struct AppleTranslationEngine: TranslationEngine {
    public init() {}
    public func translate(_ text: String, from: Language, to: Language) async throws -> String {
        let session = TranslationSession(installedSource: Locale.Language(identifier: "zh"), target: Locale.Language(identifier: "en"))
        return try await session.translate(text).targetText
    }
}

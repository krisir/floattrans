import Foundation
@preconcurrency import Translation

public enum Language: Sendable { case chinese, english }
public struct TextSnapshot: Sendable {
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let text: String
    public let selectedRange: NSRange?
    public let timestamp: Date
    public init(pid: pid_t, bundleIdentifier: String?, text: String, selectedRange: NSRange?, timestamp: Date = .now) {
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.text = text
        self.selectedRange = selectedRange
        self.timestamp = timestamp
    }
}

public struct SentenceExtractor: Sendable {
    static let sentencePunctuation: Set<Character> = ["。", "？", "！", ".", "?", "!", "；", ";"]
    static let terminators: Set<Character> = sentencePunctuation.union(["\n"])

    public init() {}
    public func extract(from snapshot: TextSnapshot, maxLength: Int = 300) -> String {
        let text = snapshot.text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        var caret = Self.caretIndex(in: text, selectedRange: snapshot.selectedRange)
        if caret > text.startIndex {
            let previous = text.index(before: caret)
            if Self.terminators.contains(text[previous]) {
                caret = previous
            }
        }
        var result = Self.fragment(in: text, caret: caret)
        if !Self.isUsable(result) {
            result = Self.previousUsableSentence(in: text, before: caret) ?? result
        }
        if result.count > maxLength { result = String(result.suffix(maxLength)) }
        return result
    }

    public func isComplete(_ snapshot: TextSnapshot) -> Bool {
        let text = snapshot.text
        guard !text.isEmpty else { return false }
        let caret = Self.caretIndex(in: text, selectedRange: snapshot.selectedRange)
        guard caret > text.startIndex else { return false }
        return Self.terminators.contains(text[text.index(before: caret)])
    }

    private static func caretIndex(in text: String, selectedRange: NSRange?) -> String.Index {
        let utf16Count = text.utf16.count
        let offset = selectedRange.map { min(max($0.location, 0), utf16Count) } ?? utf16Count
        return String.Index(utf16Offset: offset, in: text)
    }

    private static func fragment(in text: String, caret: String.Index) -> String {
        var start = caret
        while start > text.startIndex {
            let previous = text.index(before: start)
            if terminators.contains(text[previous]) { break }
            start = previous
        }
        var end = caret
        while end < text.endIndex, !terminators.contains(text[end]) {
            end = text.index(after: end)
        }
        if end < text.endIndex, sentencePunctuation.contains(text[end]) {
            end = text.index(after: end)
        }
        return String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func previousUsableSentence(in text: String, before caret: String.Index) -> String? {
        var probe = caret
        while probe > text.startIndex {
            let previous = text.index(before: probe)
            if terminators.contains(text[previous]) {
                var inPrevious = previous
                if inPrevious > text.startIndex {
                    inPrevious = text.index(before: inPrevious)
                }
                let candidate = fragment(in: text, caret: inPrevious)
                return isUsable(candidate) ? candidate : nil
            }
            probe = previous
        }
        return nil
    }

    private static func isUsable(_ sentence: String) -> Bool {
        !sentence.isEmpty && ChineseTextDetector().containsChinese(sentence)
    }
}

public struct FieldReplacement: Equatable, Sendable {
    public let prefix: String
    public let sourceWithTerminator: String
    public let suffix: String
    public let caretUTF16Offset: Int

    public var reconstructed: String { prefix + sourceWithTerminator + suffix }

    public func applying(translation: String) -> (text: String, caretUTF16Offset: Int) {
        let next = prefix + translation + suffix
        return (next, (prefix as NSString).length + (translation as NSString).length)
    }

    public static func replacing(
        fieldText: String, sourceWithTerminator: String, translation: String
    ) -> (text: String, caretUTF16Offset: Int)? {
        guard !sourceWithTerminator.isEmpty else { return nil }
        let nsField = fieldText as NSString
        let matchRange = nsField.range(of: sourceWithTerminator, options: .backwards)
        guard matchRange.location != NSNotFound else { return nil }
        let prefix = nsField.substring(to: matchRange.location)
        let suffix = nsField.substring(from: matchRange.location + matchRange.length)
        let next = prefix + translation + suffix
        return (next, (prefix as NSString).length + (translation as NSString).length)
    }

    public static func evaluate(fieldText: String, source: String) -> FieldReplacement? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let nsField = fieldText as NSString
        let sourceRange = nsField.range(of: trimmed, options: .backwards)
        guard sourceRange.location != NSNotFound else { return nil }
        let afterSource = sourceRange.location + sourceRange.length
        var terminatorLength = 0
        let alreadyHasPunctuation = trimmed.last.map { SentenceExtractor.sentencePunctuation.contains($0) } ?? false
        if !alreadyHasPunctuation, afterSource < nsField.length {
            let next = nsField.substring(with: NSRange(location: afterSource, length: 1))
            if let ch = next.first, SentenceExtractor.terminators.contains(ch) {
                terminatorLength = 1
            }
        }
        let matchLength = sourceRange.length + terminatorLength
        let matchRange = NSRange(location: sourceRange.location, length: matchLength)
        let prefix = nsField.substring(to: sourceRange.location)
        let matched = nsField.substring(with: matchRange)
        let suffix = nsField.substring(from: matchRange.location + matchRange.length)
        return FieldReplacement(
            prefix: prefix,
            sourceWithTerminator: matched,
            suffix: suffix,
            caretUTF16Offset: matchRange.location + matchRange.length)
    }
}

enum FocusedFieldReplacer {
    static func replace(
        currentText: String?,
        sourceWithTerminator: String,
        translation: String,
        write: (String, Int) -> Bool
    ) -> Bool {
        guard let currentText,
            let next = FieldReplacement.replacing(
                fieldText: currentText, sourceWithTerminator: sourceWithTerminator, translation: translation)
        else { return false }
        return write(next.text, next.caretUTF16Offset)
    }
}

public struct ChineseTextDetector: Sendable {
    public init() {}
    public func containsChinese(_ text: String) -> Bool {
        text.unicodeScalars.contains { (0x4E00...0x9FFF).contains(Int($0.value)) }
    }
}

enum ShortcutSnapshotRecovery {
    static func resolve(live: TextSnapshot, lastGoodText: String?) -> TextSnapshot {
        let extractor = SentenceExtractor()
        let detector = ChineseTextDetector()
        if detector.containsChinese(extractor.extract(from: live)) {
            return live
        }
        guard let lastGoodText else { return live }
        let recovered = TextSnapshot(
            pid: live.pid,
            bundleIdentifier: live.bundleIdentifier,
            text: lastGoodText,
            selectedRange: NSRange(location: (lastGoodText as NSString).length, length: 0),
            timestamp: live.timestamp)
        guard detector.containsChinese(extractor.extract(from: recovered)) else { return live }
        return recovered
    }
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
        generation += 1
        let current = generation
        task?.cancel()
        if let cached = cache[key] { return cached }
        let newTask = Task { try await engine.translate(key, from: .chinese, to: .english) }
        task = newTask
        do {
            let value = try await newTask.value
            guard current == generation, !Task.isCancelled else { return nil }
            cache[key] = value
            return value
        } catch {
            DiagnosticLog.write("translation error type=\(String(reflecting: error))")
            return nil
        }
    }
    public func cancel() {
        generation += 1
        task?.cancel()
        task = nil
    }
}

public protocol TranslationEngine: Sendable {
    func translate(_ text: String, from: Language, to: Language) async throws -> String
}

enum TranslationLanguages {
    static let source = Locale.Language(identifier: "zh")
    static let target = Locale.Language(identifier: "en")
}

enum TranslationSessionError: Error {
    case unavailable
}

@MainActor
final class TranslationSessionHolder {
    private var session: TranslationSession?
    private var waiters: [CheckedContinuation<TranslationSession, Error>] = []

    func attach(_ session: TranslationSession) {
        self.session = session
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume(returning: session) }
    }

    func translate(_ text: String) async throws -> String {
        try await readySession().translate(text).targetText
    }

    func prepareTranslation() async throws {
        try await readySession().prepareTranslation()
    }

    func languageAvailability() async -> LanguageAvailability.Status {
        await LanguageAvailability().status(from: TranslationLanguages.source, to: TranslationLanguages.target)
    }

    private func readySession() async throws -> TranslationSession {
        if let session { return session }
        return try await withCheckedThrowingContinuation { continuation in
            waiters.append(continuation)
            if waiters.count == 1 {
                Task { await self.failWaitersIfStillEmpty() }
            }
        }
    }

    private func failWaitersIfStillEmpty() async {
        try? await Task.sleep(for: .seconds(8))
        guard session == nil, !waiters.isEmpty else { return }
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume(throwing: TranslationSessionError.unavailable) }
    }
}

struct HostedTranslationEngine: TranslationEngine, @unchecked Sendable {
    let holder: TranslationSessionHolder
    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        try await holder.translate(text)
    }
}

import Foundation
@preconcurrency import Translation

/// Languages exposed in the translation direction pickers.
///
/// The raw values are the BCP-47 identifiers consumed by the Translation
/// framework and are stable for persistence in UserDefaults.
public enum Language: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case chinese = "zh"
    case english = "en"
    case japanese = "ja"
    case russian = "ru"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    public var id: String { rawValue }
    public var locale: Locale.Language { Locale.Language(identifier: rawValue) }

    public var englishName: String {
        switch self {
        case .chinese: return "Chinese"
        case .english: return "English"
        case .japanese: return "Japanese"
        case .russian: return "Russian"
        case .korean: return "Korean"
        case .french: return "French"
        case .german: return "German"
        case .spanish: return "Spanish"
        }
    }

    public var chineseName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "英语"
        case .japanese: return "日语"
        case .russian: return "俄语"
        case .korean: return "韩语"
        case .french: return "法语"
        case .german: return "德语"
        case .spanish: return "西班牙语"
        }
    }
}
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
        !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        LanguageTextDetector().contains(text, language: .chinese)
    }
}

/// Script-based source-text detector. Accessibility snapshots are frequently
/// short, so this intentionally does not try to statistically identify a
/// language; the language configured by the user remains authoritative.
public struct LanguageTextDetector: Sendable {
    public init() {}

    public func contains(_ text: String, language: Language) -> Bool {
        switch language {
        case .chinese:
            return text.unicodeScalars.contains(where: isHan)
        case .japanese:
            return text.unicodeScalars.contains(where: isKana) || text.unicodeScalars.contains(where: isHan)
        case .russian:
            return text.unicodeScalars.contains(where: isCyrillic)
        case .korean:
            return text.unicodeScalars.contains(where: isHangul)
        case .english, .french, .german, .spanish:
            return text.unicodeScalars.contains(where: isLatin)
        }
    }

    private func isHan(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x3400...0x4DBF).contains(value)
            || (0x4E00...0x9FFF).contains(value)
            || (0xF900...0xFAFF).contains(value)
            || (0x20000...0x323AF).contains(value)
    }
    private func isKana(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x3040...0x30FF).contains(value) || (0x31F0...0x31FF).contains(value)
            || (0xFF66...0xFF9D).contains(value)
    }
    private func isCyrillic(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x0400...0x052F).contains(value) || (0x2DE0...0x2DFF).contains(value)
            || (0xA640...0xA69F).contains(value)
    }
    private func isHangul(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x1100...0x11FF).contains(value) || (0x3130...0x318F).contains(value)
            || (0xA960...0xA97F).contains(value) || (0xAC00...0xD7AF).contains(value)
            || (0xD7B0...0xD7FF).contains(value)
    }
    private func isLatin(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x0041...0x005A).contains(value) || (0x0061...0x007A).contains(value)
            || (0x00C0...0x02AF).contains(value) || (0x1E00...0x1EFF).contains(value)
    }
}

enum ShortcutSnapshotRecovery {
    static func resolve(live: TextSnapshot, lastGoodText: String?, sourceLanguage: Language = .chinese) -> TextSnapshot {
        let extractor = SentenceExtractor()
        let detector = LanguageTextDetector()
        if detector.contains(extractor.extract(from: live), language: sourceLanguage) {
            return live
        }
        guard let lastGoodText else { return live }
        let recovered = TextSnapshot(
            pid: live.pid,
            bundleIdentifier: live.bundleIdentifier,
            text: lastGoodText,
            selectedRange: NSRange(location: (lastGoodText as NSString).length, length: 0),
            timestamp: live.timestamp)
        guard detector.contains(extractor.extract(from: recovered), language: sourceLanguage) else { return live }
        return recovered
    }
}

public actor TranslationCoordinator {
    private let engine: any TranslationEngine
    private var sourceLanguage: Language
    private var targetLanguage: Language
    private var generation = 0
    private var task: Task<String, Error>?
    private struct CacheKey: Hashable, Sendable {
        let text: String
        let source: Language
        let target: Language
    }
    private var cache: [CacheKey: String] = [:]

    public init(engine: any TranslationEngine, sourceLanguage: Language = .chinese, targetLanguage: Language = .english) {
        self.engine = engine
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    public func setDirection(from source: Language, to target: Language) {
        guard sourceLanguage != source || targetLanguage != target else { return }
        sourceLanguage = source
        targetLanguage = target
        generation += 1
        task?.cancel()
        task = nil
    }

    public func clearCache() { cache.removeAll(keepingCapacity: true) }

    public func translate(_ text: String) async -> String? {
        await translate(text, from: sourceLanguage, to: targetLanguage)
    }

    public func translate(_ text: String, from source: Language, to target: Language) async -> String? {
        let key = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        guard source != target else { return key }
        generation += 1
        let current = generation
        task?.cancel()
        let cacheKey = CacheKey(text: key, source: source, target: target)
        if let cached = cache[cacheKey] { return cached }
        let newTask = Task { try await engine.translate(key, from: source, to: target) }
        task = newTask
        do {
            let value = try await newTask.value
            guard current == generation, !Task.isCancelled else { return nil }
            cache[cacheKey] = value
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

enum TranslationSessionError: Error {
    case unavailable
}

@MainActor
final class TranslationSessionHolder {
    private var session: TranslationSession?
    private var sessionSource: Language?
    private var sessionTarget: Language?
    private var requestedSource: Language = .chinese
    private var requestedTarget: Language = .english
    private var waiters: [CheckedContinuation<TranslationSession, Error>] = []

    func attach(_ session: TranslationSession, source: Language, target: Language) {
        // A previous SwiftUI task can complete after its configuration has
        // been invalidated. Never let that old session satisfy a request for
        // the newly selected language pair.
        guard requestedSource == source, requestedTarget == target else { return }
        self.session = session
        sessionSource = source
        sessionTarget = target
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume(returning: session) }
    }

    func configure(source: Language, target: Language) {
        requestedSource = source
        requestedTarget = target
        session = nil
        sessionSource = nil
        sessionTarget = nil
    }

    func translate(_ text: String, from source: Language, to target: Language) async throws -> String {
        try await readySession(from: source, to: target).translate(text).targetText
    }

    private func readySession(from source: Language, to target: Language) async throws -> TranslationSession {
        guard requestedSource == source, requestedTarget == target else {
            throw TranslationSessionError.unavailable
        }
        if let session, sessionSource == source, sessionTarget == target { return session }
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
        try await holder.translate(text, from: from, to: to)
    }
}

/// Switches between macOS's local translator and the ordered LLM router
/// without rebuilding the coordinator while an input event is in flight.
actor TranslationService: TranslationEngine {
    private let localEngine: any TranslationEngine
    private let llmRouter: LLMModelRouter
    private var backend: TranslationBackend

    init(
        localEngine: any TranslationEngine,
        llmRouter: LLMModelRouter,
        backend: TranslationBackend,
        models: [LLMModelConfiguration],
        timeoutSeconds: Double
    ) {
        self.localEngine = localEngine
        self.llmRouter = llmRouter
        self.backend = backend
        Task {
            await llmRouter.setModels(models)
            await llmRouter.setFallbackTimeout(timeoutSeconds)
        }
    }

    func configure(backend: TranslationBackend, models: [LLMModelConfiguration], timeoutSeconds: Double) async {
        self.backend = backend
        await llmRouter.setModels(models)
        await llmRouter.setFallbackTimeout(timeoutSeconds)
    }

    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        switch backend {
        case .local:
            return try await localEngine.translate(text, from: from, to: to)
        case .languageModel:
            return try await llmRouter.translate(text, from: from, to: to)
        }
    }
}

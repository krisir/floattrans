import Foundation
import Translation

/// Languages exposed by the translation settings.
///
/// The raw values intentionally use the identifiers understood by Apple's
/// `Translation` framework. Keep these values stable: they are also suitable
/// for persisting a user's direction in `UserDefaults`.
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

    /// The BCP-47 identifier used by Foundation and Translation.
    public var localeIdentifier: String { rawValue }

    /// The Foundation locale used when constructing a Translation session.
    public var locale: Locale.Language { Locale.Language(identifier: rawValue) }

    /// Alias for code that uses Foundation's terminology.
    public var foundationLanguage: Locale.Language { locale }

    /// A stable English name useful for diagnostics and fallback UI.
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

    /// A stable Simplified Chinese name useful when the app UI is Chinese.
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

    /// A picker-friendly label containing both Chinese and English names.
    public var pickerLabel: String { "\(chineseName) / \(englishName)" }

    /// Creates a supported language from a Foundation/BCP-47 identifier.
    ///
    /// Apple may return identifiers with an underscore or a region suffix
    /// (for example `zh-Hans`); normalize those forms before matching the
    /// language component. Unknown languages return `nil` so callers can
    /// safely filter `LanguageAvailability.supportedLanguages`.
    public init?(localeIdentifier: String) {
        let normalized = localeIdentifier.replacingOccurrences(of: "_", with: "-").lowercased()
        let base = normalized.split(separator: "-").first.map(String.init) ?? normalized
        guard let language = Self.allCases.first(where: { $0.rawValue == base }) else { return nil }
        self = language
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
    public func containsChinese(_ text: String) -> Bool {
        LanguageTextDetector().contains(text, language: .chinese)
    }
}

/// Detects whether text contains characters expected for a configured source
/// language. This is deliberately script based rather than a statistical
/// language classifier: text arriving from Accessibility is often short, and
/// a deterministic check avoids sending punctuation, numbers, or empty input
/// to the translation engine.
public struct LanguageTextDetector: Sendable {
    public init() {}

    public func contains(_ text: String, language: Language) -> Bool {
        switch language {
        case .chinese:
            return text.unicodeScalars.contains(where: isHan)
        case .japanese:
            // Japanese commonly mixes kana and kanji. A kanji-only sentence
            // is indistinguishable from Chinese at the script level, but is
            // still valid input when Japanese is explicitly selected.
            return text.unicodeScalars.contains(where: isKana) || text.unicodeScalars.contains(where: isHan)
        case .russian:
            return text.unicodeScalars.contains(where: isCyrillic)
        case .korean:
            return text.unicodeScalars.contains(where: isHangul)
        case .english, .french, .german, .spanish:
            // These languages all use the Latin script. The configured
            // language determines the translation direction; script detection
            // only decides whether there is meaningful text to translate.
            return text.unicodeScalars.contains(where: isLatin)
        }
    }

    /// Descriptive alias for callers that prefer a more explicit label.
    public func containsText(_ text: String, for language: Language) -> Bool {
        contains(text, language: language)
    }

    /// Attempts a lightweight script-based language guess.
    ///
    /// The result is intended as a fallback for diagnostics or an automatic
    /// source-language mode, not as a replacement for an explicit setting.
    public func detectLanguage(_ text: String) -> Language? {
        let scalars = text.unicodeScalars
        if scalars.contains(where: isKana) { return .japanese }
        if scalars.contains(where: isHangul) { return .korean }
        if scalars.contains(where: isCyrillic) { return .russian }
        if scalars.contains(where: isHan) { return .chinese }
        if scalars.contains(where: isLatin) { return .english }
        return nil
    }

    public func containsChinese(_ text: String) -> Bool {
        contains(text, language: .chinese)
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
        return (0x3040...0x30FF).contains(value)
            || (0x31F0...0x31FF).contains(value)
            || (0xFF66...0xFF9D).contains(value)
    }

    private func isCyrillic(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x0400...0x052F).contains(value)
            || (0x2DE0...0x2DFF).contains(value)
            || (0xA640...0xA69F).contains(value)
    }

    private func isHangul(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x1100...0x11FF).contains(value)
            || (0x3130...0x318F).contains(value)
            || (0xA960...0xA97F).contains(value)
            || (0xAC00...0xD7AF).contains(value)
            || (0xD7B0...0xD7FF).contains(value)
    }

    private func isLatin(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        return (0x0041...0x005A).contains(value)
            || (0x0061...0x007A).contains(value)
            || (0x00C0...0x02AF).contains(value)
            || (0x1E00...0x1EFF).contains(value)
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

    /// Backwards-compatible initializer: Chinese → English remains the
    /// default direction when no settings have been configured yet.
    public init(engine: any TranslationEngine) {
        self.init(engine: engine, sourceLanguage: .chinese, targetLanguage: .english)
    }

    public init(
        engine: any TranslationEngine,
        sourceLanguage: Language,
        targetLanguage: Language
    ) {
        self.engine = engine
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    /// Changes the default direction used by `translate(_:)` and cancels an
    /// in-flight request so an old direction can never overwrite new output.
    public func setDirection(from source: Language, to target: Language) {
        guard sourceLanguage != source || targetLanguage != target else { return }
        sourceLanguage = source
        targetLanguage = target
        generation += 1
        task?.cancel()
        task = nil
    }

    public func direction() -> (source: Language, target: Language) {
        (sourceLanguage, targetLanguage)
    }

    public func translate(_ text: String) async -> String? {
        await translate(text, from: sourceLanguage, to: targetLanguage)
    }

    /// Translates one string using an explicit direction without changing the
    /// coordinator's configured default.
    public func translate(_ text: String, from source: Language, to target: Language) async -> String? {
        let key = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
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

    /// Invalidates cached results after a backend, prompt, or model-order
    /// change. Translation output is configuration-dependent even when the
    /// source text and language pair stay the same.
    public func clearCache() {
        cache.removeAll(keepingCapacity: true)
    }
}

public protocol TranslationEngine: Sendable {
    func translate(_ text: String, from: Language, to: Language) async throws -> String
}

public struct DemoTranslationEngine: TranslationEngine {
    public init() {}
    public func translate(_ text: String, from: Language, to: Language) async throws -> String {
        // Replace this adapter with Apple Translation when the deployment SDK exposes Translation.framework.
        let known: [String: String] = [
            "我晚点看一下": "I'll take a look later.", "明天继续": "I'll continue tomorrow.", "你好": "Hello.",
        ]
        if from == .chinese, to == .english, let value = known[text] { return value }
        if to == .english { return "(English translation) " + text }
        return "(\(to.englishName) translation) " + text
    }
}

/// Stable runtime facade that lets the app switch between Apple's local
/// engine and the ordered LLM fail-over router without replacing the
/// `TranslationCoordinator` (and without racing an in-flight request).
///
/// This type intentionally remains internal: the public extension surface is
/// `TranslationEngine`, while the concrete backend selection is an app
/// setting. All mutable state is actor-isolated and model snapshots are
/// value-types, so API keys never cross the UI actor by reference.
actor TranslationService: TranslationEngine {
    private let localEngine: any TranslationEngine
    private let llmRouter: LLMModelRouter
    private var backend: TranslationBackend

    init(
        localEngine: any TranslationEngine,
        llmRouter: LLMModelRouter,
        backend: TranslationBackend = .local,
        models: [LLMModelConfiguration] = [],
        timeoutSeconds: Double = 8
    ) {
        self.localEngine = localEngine
        self.llmRouter = llmRouter
        self.backend = backend
        // The actor's asynchronous setters are called by `configure` before
        // the first user request. Keeping this initializer synchronous makes
        // AppState construction deterministic on the main actor.
        Task {
            await llmRouter.setModels(models)
            await llmRouter.setFallbackTimeout(timeoutSeconds)
        }
    }

    func configure(
        backend: TranslationBackend,
        models: [LLMModelConfiguration],
        timeoutSeconds: Double
    ) async {
        self.backend = backend
        await llmRouter.setModels(models)
        await llmRouter.setFallbackTimeout(timeoutSeconds)
    }

    func currentBackend() -> TranslationBackend { backend }

    func translate(_ text: String, from: Language, to: Language) async throws -> String {
        switch backend {
        case .local:
            return try await localEngine.translate(text, from: from, to: to)
        case .languageModel:
            return try await llmRouter.translate(text, from: from, to: to)
        }
    }
}

@available(macOS 26.0, *)
public struct AppleTranslationEngine: TranslationEngine {
    public init() {}

    public func translate(_ text: String, from: Language, to: Language) async throws -> String {
        guard from != to else {
            throw TranslationError.unsupportedLanguagePairing
        }
        let session = TranslationSession(installedSource: from.locale, target: to.locale)
        return try await session.translate(text).targetText
    }

    /// Checks whether the source/target language assets are installed and
    /// usable. `.supported` means the pair is supported but still needs a
    /// download; `.unsupported` means the system has no model for that pair.
    public static func availabilityStatus(
        from source: Language,
        to target: Language
    ) async -> LanguageAvailability.Status {
        guard source != target else { return .unsupported }
        let availability = LanguageAvailability()
        return await availability.status(from: source.locale, to: target.locale)
    }

    /// Short alias convenient for settings views and callers that already use
    /// the term “status”.
    public static func status(
        from source: Language,
        to target: Language
    ) async -> LanguageAvailability.Status {
        await availabilityStatus(from: source, to: target)
    }

    /// Returns the language identifiers advertised by the current macOS
    /// installation, filtered to the language choices exposed by FloatTrans.
    public static func supportedLanguages() async -> [Language] {
        let availability = LanguageAvailability()
        let supported = await availability.supportedLanguages
        var result: [Language] = []
        for localeLanguage in supported {
            if let language = Language(localeIdentifier: localeLanguage.minimalIdentifier), !result.contains(language) {
                result.append(language)
            }
        }
        return result
    }

    /// Asks Translation to prepare installed resources. On current macOS this
    /// direct (non-SwiftUI) initializer is intentionally non-interactive; if a
    /// language pack is missing it throws `TranslationError.notInstalled`.
    /// Settings UIs that want to display Apple's download consent sheet should
    /// use a SwiftUI `.translationTask` with the same configuration and call
    /// `prepareTranslation()` there.
    public static func prepare(from source: Language, to target: Language) async throws {
        guard source != target else { throw TranslationError.unsupportedLanguagePairing }
        let session = TranslationSession(installedSource: source.locale, target: target.locale)
        try await session.prepareTranslation()
    }
}

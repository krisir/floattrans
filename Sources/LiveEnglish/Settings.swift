import AppKit
import Foundation
import ServiceManagement

enum OverlayTextSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    var points: CGFloat {
        switch self {
        case .small: return 15
        case .medium: return 18
        case .large: return 22
        }
    }
    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .small: return L10n.sizeSmall(lang)
        case .medium: return L10n.sizeMedium(lang)
        case .large: return L10n.sizeLarge(lang)
        }
    }
}

enum OverlayPosition: String, CaseIterable {
    case topRight = "Top Right"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"

    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .topRight: return L10n.positionTopRight(lang)
        case .bottomCenter: return L10n.positionBottomCenter(lang)
        case .bottomRight: return L10n.positionBottomRight(lang)
        }
    }
    var symbolName: String {
        switch self {
        case .topRight: return "rectangle.topright.inset.filled"
        case .bottomCenter: return "rectangle.bottomhalf.inset.filled"
        case .bottomRight: return "rectangle.bottomright.inset.filled"
        }
    }
}

enum OverlayBehavior: String, CaseIterable {
    case replace = "Replace Previous"
    case stack = "Stack Below"
    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .replace: return L10n.behaviorReplace(lang)
        case .stack: return L10n.behaviorStack(lang)
        }
    }
}

enum TranslationSpeed: Int, CaseIterable {
    case fast = 300
    case balanced = 450
    case relaxed = 700
}

/// Selects the engine used for new translation requests.
enum TranslationBackend: String, CaseIterable, Codable, Identifiable, Sendable, Hashable {
    case local
    case languageModel = "language-model"

    var id: String { rawValue }

    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .local: return L10n.backendLocal(lang)
        case .languageModel: return L10n.backendLanguageModel(lang)
        }
    }
}

enum TranslationTiming: String, CaseIterable, Sendable {
    case pause = "Pause"
    case completeSentence = "Complete Sentence"
    case shortcut = "Shortcut"

    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .pause: return L10n.timingPause(lang)
        case .completeSentence: return L10n.timingCompleteSentence(lang)
        case .shortcut: return L10n.timingShortcut(lang)
        }
    }
}

/// The concrete event that produced a translation result. This is kept
/// separate from the current setting so a result cannot be spoken using a
/// newer, unrelated timing selection.
enum TranslationEvent: String, Sendable {
    case pause
    case completeSentence
    case shortcut

    var timing: TranslationTiming {
        switch self {
        case .pause: return .pause
        case .completeSentence: return .completeSentence
        case .shortcut: return .shortcut
        }
    }
}

/// The translation events that may trigger text-to-speech. Pause-triggered
/// translation is intentionally excluded because speaking while the user is
/// still composing is disruptive.
enum SpeechTrigger: Int, CaseIterable, Identifiable, Sendable {
    case completeSentence = 2
    case shortcut = 4

    var id: Int { rawValue }

    var translationTiming: TranslationTiming {
        switch self {
        case .completeSentence: return .completeSentence
        case .shortcut: return .shortcut
        }
    }
}

struct SpeechTriggerSelection: OptionSet, Codable, Equatable, Sendable {
    let rawValue: Int

    static let pause = SpeechTriggerSelection(rawValue: 1)
    static let completeSentence = SpeechTriggerSelection(rawValue: SpeechTrigger.completeSentence.rawValue)
    static let shortcut = SpeechTriggerSelection(rawValue: SpeechTrigger.shortcut.rawValue)
    static let all: SpeechTriggerSelection = [.completeSentence, .shortcut]

    init(rawValue: Int) { self.rawValue = rawValue }

    init(timing: TranslationTiming) {
        switch timing {
        case .pause: self = .pause
        case .completeSentence: self = .completeSentence
        case .shortcut: self = .shortcut
        }
    }

    static func normalized(rawValue: Int) -> SpeechTriggerSelection {
        SpeechTriggerSelection(rawValue: rawValue & SpeechTriggerSelection.all.rawValue)
    }
}

struct ReplaceShortcut: Equatable, Sendable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    static let controlKeyFlag: UInt32 = 1 << 12
    static let shiftKeyFlag: UInt32 = 1 << 9
    static let optionKeyFlag: UInt32 = 1 << 11
    static let commandKeyFlag: UInt32 = 1 << 8
    static let returnKeyCode: UInt32 = 0x24
    static let cKeyCode: UInt32 = 0x08
    static let tKeyCode: UInt32 = 0x11
    static let leftBracketKeyCode: UInt32 = 0x21
    static let rightBracketKeyCode: UInt32 = 0x1E
    static let escapeKeyCode: UInt32 = 0x35

    static let controlShiftReturn = ReplaceShortcut(
        keyCode: returnKeyCode, carbonModifiers: controlKeyFlag | shiftKeyFlag)
    static let controlShiftC = ReplaceShortcut(
        keyCode: cKeyCode, carbonModifiers: controlKeyFlag | shiftKeyFlag)
    static let controlShiftT = ReplaceShortcut(
        keyCode: tKeyCode, carbonModifiers: controlKeyFlag | shiftKeyFlag)
    static let optionShiftLeftBracket = ReplaceShortcut(
        keyCode: leftBracketKeyCode, carbonModifiers: optionKeyFlag | shiftKeyFlag)
    static let optionShiftRightBracket = ReplaceShortcut(
        keyCode: rightBracketKeyCode, carbonModifiers: optionKeyFlag | shiftKeyFlag)

    var displayString: String {
        var parts = ""
        if carbonModifiers & Self.controlKeyFlag != 0 { parts += "⌃" }
        if carbonModifiers & Self.optionKeyFlag != 0 { parts += "⌥" }
        if carbonModifiers & Self.shiftKeyFlag != 0 { parts += "⇧" }
        if carbonModifiers & Self.commandKeyFlag != 0 { parts += "⌘" }
        parts += Self.glyph(for: keyCode)
        return parts
    }

    static func from(event: NSEvent) -> ReplaceShortcut? {
        if UInt32(event.keyCode) == escapeKeyCode { return nil }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= controlKeyFlag }
        if flags.contains(.option) { carbon |= optionKeyFlag }
        if flags.contains(.shift) { carbon |= shiftKeyFlag }
        if flags.contains(.command) { carbon |= commandKeyFlag }
        guard carbon & (controlKeyFlag | optionKeyFlag | commandKeyFlag) != 0 else { return nil }
        return ReplaceShortcut(keyCode: UInt32(event.keyCode), carbonModifiers: carbon)
    }

    private static func glyph(for keyCode: UInt32) -> String {
        switch keyCode {
        case 0x24, 0x4C: return "↩"
        case 0x30: return "⇥"
        case 0x31: return "Space"
        case 0x33: return "⌫"
        case 0x35: return "⎋"
        default:
            let letters: [UInt32: String] = [
                0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G", 0x06: "Z", 0x07: "X",
                0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y",
                0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
                0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]", 0x1F: "O",
                0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K",
                0x29: ";", 0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".",
                0x32: "`",
            ]
            return letters[keyCode] ?? "Key \(keyCode)"
        }
    }
}

@MainActor final class SettingsStore: ObservableObject {
    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: "enabled") } }
    @Published var hideAfter: Double {
        didSet {
            let clamped = min(max(hideAfter, 5), 60)
            if hideAfter != clamped {
                hideAfter = clamped
                return
            }
            defaults.set(hideAfter, forKey: "hideAfter")
        }
    }
    @Published var neverHide: Bool { didSet { defaults.set(neverHide, forKey: "neverHide") } }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem(launchAtLogin)
        }
    }
    @Published var textSize: OverlayTextSize { didSet { defaults.set(textSize.rawValue, forKey: "textSize") } }
    @Published var overlayPosition: OverlayPosition {
        didSet { defaults.set(overlayPosition.rawValue, forKey: "overlayPosition") }
    }
    @Published var overlayEdgeDistance: Double {
        didSet { defaults.set(overlayEdgeDistance, forKey: "overlayEdgeDistance") }
    }
    @Published var overlayBehavior: OverlayBehavior {
        didSet { defaults.set(overlayBehavior.rawValue, forKey: "overlayBehavior") }
    }
    @Published var uiLanguage: UILanguage { didSet { defaults.set(uiLanguage.rawValue, forKey: "uiLanguage") } }
    @Published var sourceLanguage: Language {
        didSet {
            defaults.set(sourceLanguage.rawValue, forKey: "sourceLanguage")
            onTranslationSettingsChanged?()
        }
    }
    @Published var targetLanguage: Language {
        didSet {
            defaults.set(targetLanguage.rawValue, forKey: "targetLanguage")
            onTranslationSettingsChanged?()
        }
    }
    @Published var translationBackend: TranslationBackend {
        didSet {
            defaults.set(translationBackend.rawValue, forKey: "translationBackend")
            if translationBackend == .languageModel {
                ensureAPIKeysAvailable()
            }
            onTranslationSettingsChanged?()
        }
    }
    @Published var llmModels: [LLMModelConfiguration] {
        didSet {
            persistLLMModels()
            onTranslationSettingsChanged?()
        }
    }
    @Published var llmFallbackTimeout: Double {
        didSet {
            let normalized = Self.clampLLMTimeout(llmFallbackTimeout)
            if llmFallbackTimeout != normalized {
                llmFallbackTimeout = normalized
                return
            }
            defaults.set(llmFallbackTimeout, forKey: "llmFallbackTimeout")
            onTranslationSettingsChanged?()
        }
    }
    @Published var translationSpeed: Int {
        didSet {
            let normalized = TranslationSpeed(rawValue: translationSpeed)?.rawValue ?? TranslationSpeed.balanced.rawValue
            if translationSpeed != normalized {
                translationSpeed = normalized
                return
            }
            defaults.set(translationSpeed, forKey: "translationSpeed")
        }
    }
    @Published var pauseCommitDelay: Double {
        didSet {
            let normalized = Self.clampPauseCommitDelay(pauseCommitDelay)
            if pauseCommitDelay != normalized {
                pauseCommitDelay = normalized
                return
            }
            defaults.set(pauseCommitDelay, forKey: "pauseCommitDelay")
        }
    }
    @Published var historyRetention: HistoryRetention {
        didSet {
            defaults.set(historyRetention.rawValue, forKey: "historyRetention")
            onHistoryRetentionChanged?()
        }
    }
    @Published var translationTiming: TranslationTiming {
        didSet { defaults.set(translationTiming.rawValue, forKey: "translationTiming") }
    }
    @Published var speechEnabled: Bool {
        didSet {
            defaults.set(speechEnabled, forKey: "speechEnabled")
            if speechEnabled, speechTriggers.isEmpty {
                speechTriggers = .all
            } else if !speechEnabled, !speechTriggers.isEmpty {
                speechTriggers = []
            }
        }
    }
    @Published var speechTriggers: SpeechTriggerSelection {
        didSet {
            let normalized = SpeechTriggerSelection.normalized(rawValue: speechTriggers.rawValue)
            if speechTriggers != normalized {
                speechTriggers = normalized
                return
            }
            defaults.set(speechTriggers.rawValue, forKey: "speechTriggers")
            let enabled = !speechTriggers.isEmpty
            if speechEnabled != enabled { speechEnabled = enabled }
        }
    }
    @Published var replaceOriginal: Bool { didSet { defaults.set(replaceOriginal, forKey: "replaceOriginal") } }
    @Published var copyTranslation: Bool { didSet { defaults.set(copyTranslation, forKey: "copyTranslation") } }
    @Published var replaceShortcut: ReplaceShortcut {
        didSet { persistShortcut(replaceShortcut, keyCodeKey: "replaceShortcutKeyCode", modifiersKey: "replaceShortcutModifiers") }
    }
    @Published var copyShortcut: ReplaceShortcut {
        didSet { persistShortcut(copyShortcut, keyCodeKey: "copyShortcutKeyCode", modifiersKey: "copyShortcutModifiers") }
    }
    @Published var translateShortcut: ReplaceShortcut {
        didSet {
            persistShortcut(
                translateShortcut, keyCodeKey: "translateShortcutKeyCode", modifiersKey: "translateShortcutModifiers")
        }
    }
    @Published var excludedBundleIDs: Set<String> {
        didSet { defaults.set(Array(excludedBundleIDs), forKey: "excludedBundleIDs") }
    }
    /// Assigned by AppState after its translation pipeline has been built.
    var onTranslationSettingsChanged: (() -> Void)?
    /// Reloads and immediately prunes local history after the user shortens
    /// the selected retention period.
    var onHistoryRetentionChanged: (() -> Void)?
    private let defaults = UserDefaults.standard
    private let keychain: any APIKeyStore
    /// Keys stay in Keychain until language-model translation needs them, so
    /// a local-translation launch does not prompt for Keychain access.
    private var apiKeysLoaded = false

    init(keychain: any APIKeyStore = KeychainStore()) {
        self.keychain = keychain
        enabled = defaults.object(forKey: "enabled") as? Bool ?? true
        let storedHideAfter = defaults.object(forKey: "hideAfter") as? Double
        let hideAfterValue = min(max(storedHideAfter ?? 5, 5), 60)
        hideAfter = hideAfterValue
        if storedHideAfter != hideAfterValue { defaults.set(hideAfterValue, forKey: "hideAfter") }
        neverHide = defaults.object(forKey: "neverHide") as? Bool ?? false
        launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        textSize = OverlayTextSize(rawValue: defaults.string(forKey: "textSize") ?? "Medium") ?? .medium
        overlayPosition =
            OverlayPosition(rawValue: defaults.string(forKey: "overlayPosition") ?? "Bottom Center") ?? .bottomCenter
        overlayEdgeDistance = min(max(defaults.object(forKey: "overlayEdgeDistance") as? Double ?? 48, 0), 300)
        let storedBehavior = defaults.string(forKey: "overlayBehavior")
        if storedBehavior == "Keep Previous" {
            overlayBehavior = .stack
            defaults.set(OverlayBehavior.stack.rawValue, forKey: "overlayBehavior")
        } else {
            overlayBehavior = OverlayBehavior(rawValue: storedBehavior ?? OverlayBehavior.replace.rawValue) ?? .replace
        }
        uiLanguage =
            UILanguage(rawValue: defaults.string(forKey: "uiLanguage") ?? UILanguage.chinese.rawValue) ?? .chinese
        let storedSource = Self.readLanguage(defaults.string(forKey: "sourceLanguage"), fallback: .chinese)
        let storedTarget = Self.readLanguage(defaults.string(forKey: "targetLanguage"), fallback: .english)
        sourceLanguage = storedSource
        targetLanguage = storedTarget == storedSource ? (storedSource == .english ? .chinese : .english) : storedTarget
        translationBackend = TranslationBackend(rawValue: defaults.string(forKey: "translationBackend") ?? "") ?? .local
        llmModels = Self.readLLMModels(defaults.data(forKey: "llmModels"))
        llmFallbackTimeout = Self.clampLLMTimeout(defaults.object(forKey: "llmFallbackTimeout") as? Double ?? 8)
        let speedValue = TranslationSpeed(rawValue: defaults.object(forKey: "translationSpeed") as? Int ?? 450)?.rawValue
            ?? TranslationSpeed.balanced.rawValue
        translationSpeed = speedValue
        pauseCommitDelay = Self.clampPauseCommitDelay(defaults.object(forKey: "pauseCommitDelay") as? Double ?? 1.0)
        historyRetention = HistoryRetention(rawValue: defaults.string(forKey: "historyRetention") ?? "") ?? .none
        translationTiming =
            TranslationTiming(rawValue: defaults.string(forKey: "translationTiming") ?? TranslationTiming.pause.rawValue)
            ?? .pause
        let legacySpeechEnabled = defaults.object(forKey: "speechEnabled") as? Bool ?? false
        let initialSpeechTriggers: SpeechTriggerSelection
        if let storedSpeechTriggers = defaults.object(forKey: "speechTriggers") as? Int {
            initialSpeechTriggers = SpeechTriggerSelection.normalized(rawValue: storedSpeechTriggers)
        } else {
            // Preserve the old behavior for existing users: it only spoke
            // completed sentences and shortcut-triggered translations.
            initialSpeechTriggers = legacySpeechEnabled ? [.completeSentence, .shortcut] : []
        }
        speechTriggers = initialSpeechTriggers
        speechEnabled = !initialSpeechTriggers.isEmpty
        replaceOriginal = defaults.object(forKey: "replaceOriginal") as? Bool ?? false
        copyTranslation = defaults.object(forKey: "copyTranslation") as? Bool ?? false
        replaceShortcut = Self.loadShortcut(
            defaults: defaults, keyCodeKey: "replaceShortcutKeyCode", modifiersKey: "replaceShortcutModifiers",
            fallback: .optionShiftLeftBracket)
        copyShortcut = Self.loadShortcut(
            defaults: defaults, keyCodeKey: "copyShortcutKeyCode", modifiersKey: "copyShortcutModifiers",
            fallback: .optionShiftRightBracket)
        translateShortcut = Self.loadShortcut(
            defaults: defaults, keyCodeKey: "translateShortcutKeyCode", modifiersKey: "translateShortcutModifiers",
            fallback: .controlShiftT)
        excludedBundleIDs = Set(
            defaults.stringArray(forKey: "excludedBundleIDs") ?? [
                "com.agilebits.onepassword7", "com.apple.keychainaccess", "com.apple.dt.Xcode", "com.openai.codex",
                "cc.kristar.floattrans",
            ])
        if translationBackend == .languageModel {
            ensureAPIKeysAvailable()
        }
        if defaults.object(forKey: "translationSpeed") == nil {
            defaults.set(speedValue, forKey: "translationSpeed")
        }
        if defaults.object(forKey: "pauseCommitDelay") == nil {
            defaults.set(pauseCommitDelay, forKey: "pauseCommitDelay")
        }
        if defaults.object(forKey: "historyRetention") == nil {
            defaults.set(historyRetention.rawValue, forKey: "historyRetention")
        }
        if defaults.object(forKey: "sourceLanguage") == nil { defaults.set(sourceLanguage.rawValue, forKey: "sourceLanguage") }
        if defaults.object(forKey: "targetLanguage") == nil { defaults.set(targetLanguage.rawValue, forKey: "targetLanguage") }
        if defaults.object(forKey: "translationBackend") == nil {
            defaults.set(translationBackend.rawValue, forKey: "translationBackend")
        }
        if defaults.object(forKey: "llmFallbackTimeout") == nil {
            defaults.set(llmFallbackTimeout, forKey: "llmFallbackTimeout")
        }
        if defaults.object(forKey: "speechTriggers") == nil {
            defaults.set(speechTriggers.rawValue, forKey: "speechTriggers")
        }
        if defaults.object(forKey: "speechEnabled") == nil {
            defaults.set(speechEnabled, forKey: "speechEnabled")
        }
    }

    func updateLLMModel(_ model: LLMModelConfiguration) {
        guard let index = llmModels.firstIndex(where: { $0.id == model.id }) else { return }
        var updated = model
        // Timeout is global so one clear setting governs fail-over order.
        updated.timeoutSeconds = 0
        llmModels[index] = updated
    }

    func addLLMModel(_ model: LLMModelConfiguration) {
        var model = model
        model.timeoutSeconds = 0
        llmModels.append(model)
    }

    func removeLLMModel(id: UUID) {
        llmModels.removeAll { $0.id == id }
        try? keychain.deleteAPIKey(forModelID: id)
    }

    func moveLLMModels(from offsets: IndexSet, to destination: Int) {
        llmModels.move(fromOffsets: offsets, toOffset: destination)
    }

    private static func loadShortcut(
        defaults: UserDefaults, keyCodeKey: String, modifiersKey: String, fallback: ReplaceShortcut
    ) -> ReplaceShortcut {
        guard defaults.object(forKey: keyCodeKey) != nil, defaults.object(forKey: modifiersKey) != nil else {
            return fallback
        }
        return ReplaceShortcut(
            keyCode: UInt32(defaults.integer(forKey: keyCodeKey)),
            carbonModifiers: UInt32(defaults.integer(forKey: modifiersKey)))
    }

    private func persistShortcut(_ shortcut: ReplaceShortcut, keyCodeKey: String, modifiersKey: String) {
        defaults.set(Int(shortcut.keyCode), forKey: keyCodeKey)
        defaults.set(Int(shortcut.carbonModifiers), forKey: modifiersKey)
    }

    private static func readLanguage(_ rawValue: String?, fallback: Language) -> Language {
        guard let rawValue, let value = Language(rawValue: rawValue) else { return fallback }
        return value
    }

    private static func readLLMModels(_ data: Data?) -> [LLMModelConfiguration] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([LLMModelConfiguration].self, from: data)) ?? []
    }

    private func persistLLMModels() {
        var publicModels = llmModels
        if apiKeysLoaded {
            for index in publicModels.indices {
                let model = publicModels[index]
                if model.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    try? keychain.deleteAPIKey(forModelID: model.id)
                } else {
                    try? keychain.setAPIKey(model.apiKey, forModelID: model.id)
                }
                publicModels[index].apiKey = ""
                publicModels[index].timeoutSeconds = 0
            }
        } else {
            for index in publicModels.indices {
                publicModels[index].apiKey = ""
                publicModels[index].timeoutSeconds = 0
            }
        }
        guard let data = try? JSONEncoder().encode(publicModels) else { return }
        defaults.set(data, forKey: "llmModels")
    }

    private func ensureAPIKeysAvailable() {
        guard !apiKeysLoaded else { return }
        apiKeysLoaded = true
        restoreAPIKeysFromKeychain()
        migrateLegacyAPIKeysToKeychain()
    }

    private func restoreAPIKeysFromKeychain() {
        var models = llmModels
        var changed = false
        for index in models.indices {
            if let value = try? keychain.apiKey(forModelID: models[index].id), !value.isEmpty {
                models[index].apiKey = value
                changed = true
            }
        }
        if changed { llmModels = models }
    }

    private func migrateLegacyAPIKeysToKeychain() {
        // Models written by earlier preview builds may contain a plaintext
        // key in the preferences blob. Import it once and immediately rewrite
        // the public snapshot with an empty key.
        guard llmModels.contains(where: { !$0.apiKey.isEmpty }) else { return }
        persistLLMModels()
    }

    private static func clampLLMTimeout(_ value: Double) -> Double {
        guard value.isFinite else { return 8 }
        return min(max(value, 1), 120)
    }

    private static func clampPauseCommitDelay(_ value: Double) -> Double {
        guard value.isFinite else { return 1.0 }
        return min(max(value, 0.5), 2.0)
    }

    private func updateLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // unavailable for an unbundled debug executable
        }
    }
}

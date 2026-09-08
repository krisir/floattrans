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

/// Selects the translation backend used by the live pipeline.
///
/// Local is the privacy-preserving default and uses Apple's on-device
/// Translation framework where available. Language model mode sends text to
/// the first enabled model in the configured fail-over list.
enum TranslationBackend: String, CaseIterable, Codable, Identifiable, Sendable, Hashable {
    case local
    case languageModel = "language-model"

    var id: String { rawValue }

    /// Aliases keep the setting pleasant to use from tests and integrations.
    static var apple: TranslationBackend { .local }
    static var llm: TranslationBackend { .languageModel }

    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .local: return L10n.backendLocal(lang)
        case .languageModel: return L10n.backendLanguageModel(lang)
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
    @Published var excludedBundleIDs: Set<String> {
        didSet { defaults.set(Array(excludedBundleIDs), forKey: "excludedBundleIDs") }
    }
    /// Called by AppState after construction so runtime services follow
    /// settings edits immediately. It is intentionally main-actor isolated.
    var onTranslationSettingsChanged: (() -> Void)?

    /// Compatibility aliases for callers that use the longer setting names.
    var translationSourceLanguage: Language {
        get { sourceLanguage }
        set { sourceLanguage = newValue }
    }
    var translationTargetLanguage: Language {
        get { targetLanguage }
        set { targetLanguage = newValue }
    }
    var llmConfigurations: [LLMModelConfiguration] {
        get { llmModels }
        set { llmModels = newValue }
    }
    var modelConfigurations: [LLMModelConfiguration] {
        get { llmModels }
        set { llmModels = newValue }
    }
    var llmTimeoutSeconds: Double {
        get { llmFallbackTimeout }
        set { llmFallbackTimeout = newValue }
    }

    /// Update one model in-place while preserving the order used for
    /// fail-over. SwiftUI bindings call this helper so edits to a struct
    /// element reliably trigger `@Published` and persistence.
    func updateLLMModel(_ model: LLMModelConfiguration) {
        guard let index = llmModels.firstIndex(where: { $0.id == model.id }) else { return }
        var updated = model
        // The visible timeout control is global. A zero per-model value tells
        // the router to use that global threshold for every model.
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
        try? KeychainStore().deleteAPIKey(forModelID: id)
    }

    func moveLLMModels(from offsets: IndexSet, to destination: Int) {
        llmModels.move(fromOffsets: offsets, toOffset: destination)
    }

    private let defaults = UserDefaults.standard

    init() {
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
        let normalizedTarget: Language
        if storedTarget == storedSource {
            normalizedTarget = storedSource == .english ? .chinese : .english
        } else {
            normalizedTarget = storedTarget
        }
        sourceLanguage = storedSource
        targetLanguage = normalizedTarget
        translationBackend =
            TranslationBackend(rawValue: defaults.string(forKey: "translationBackend") ?? "") ?? .local
        llmModels = Self.readLLMModels(defaults.data(forKey: "llmModels"))
        llmFallbackTimeout = Self.clampLLMTimeout(defaults.object(forKey: "llmFallbackTimeout") as? Double ?? 8)
        let speedValue = TranslationSpeed(rawValue: defaults.object(forKey: "translationSpeed") as? Int ?? 450)?.rawValue
            ?? TranslationSpeed.balanced.rawValue
        translationSpeed = speedValue
        excludedBundleIDs = Set(
            defaults.stringArray(forKey: "excludedBundleIDs") ?? [
                "com.agilebits.onepassword7", "com.apple.keychainaccess", "com.apple.dt.Xcode", "com.openai.codex",
                "cc.kristar.floattrans",
            ])
        restoreAPIKeysFromKeychain()
        if defaults.object(forKey: "translationSpeed") == nil {
            defaults.set(speedValue, forKey: "translationSpeed")
        }
        if defaults.object(forKey: "sourceLanguage") == nil {
            defaults.set(sourceLanguage.rawValue, forKey: "sourceLanguage")
        }
        if defaults.object(forKey: "targetLanguage") == nil {
            defaults.set(targetLanguage.rawValue, forKey: "targetLanguage")
        }
        if defaults.object(forKey: "translationBackend") == nil {
            defaults.set(translationBackend.rawValue, forKey: "translationBackend")
        }
        if defaults.object(forKey: "llmFallbackTimeout") == nil {
            defaults.set(llmFallbackTimeout, forKey: "llmFallbackTimeout")
        }
        migrateAPIKeysToKeychain()
    }

    private static func readLanguage(_ rawValue: String?, fallback: Language) -> Language {
        guard let rawValue, let language = Language(rawValue: rawValue) else { return fallback }
        return language
    }

    private static func readLLMModels(_ data: Data?) -> [LLMModelConfiguration] {
        guard let data else { return [] }
        return (try? JSONDecoder().decode([LLMModelConfiguration].self, from: data)) ?? []
    }

    private func persistLLMModels() {
        // Secrets never need to be in the preferences plist. Keep an empty
        // value in the Codable snapshot and store each key in Keychain.
        var publicModels = llmModels
        let keychain = KeychainStore()
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
        guard let data = try? JSONEncoder().encode(publicModels) else { return }
        defaults.set(data, forKey: "llmModels")
    }

    private func migrateAPIKeysToKeychain() {
        let keychain = KeychainStore()
        var changed = false
        for index in llmModels.indices {
            let id = llmModels[index].id
            if let stored = try? keychain.apiKey(forModelID: id), !stored.isEmpty {
                if llmModels[index].apiKey != stored {
                    llmModels[index].apiKey = stored
                }
            } else if !llmModels[index].apiKey.isEmpty {
                // Import a legacy plaintext key once, then clear it from the
                // in-memory Codable value before preferences are rewritten.
                try? keychain.setAPIKey(llmModels[index].apiKey, forModelID: id)
                llmModels[index].apiKey = llmModels[index].apiKey
                changed = true
            }
            if llmModels[index].timeoutSeconds != 0 {
                llmModels[index].timeoutSeconds = 0
                changed = true
            }
        }
        if changed { persistLLMModels() }
    }

    private func restoreAPIKeysFromKeychain() {
        let keychain = KeychainStore()
        for index in llmModels.indices {
            if let value = try? keychain.apiKey(forModelID: llmModels[index].id), !value.isEmpty {
                llmModels[index].apiKey = value
            }
        }
    }

    private static func clampLLMTimeout(_ value: Double) -> Double {
        guard value.isFinite else { return 8 }
        return min(max(value, 0.2), 300)
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

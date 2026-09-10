import XCTest

@testable import LiveEnglish

@MainActor
final class SettingsStoreTests: XCTestCase {
    private let keys = [
        "enabled", "hideAfter", "neverHide", "launchAtLogin", "textSize", "overlayPosition", "overlayEdgeDistance",
        "overlayBehavior", "uiLanguage", "translationSpeed", "speechEnabled", "speechTriggers", "speechVoiceIdentifier", "speechVoiceIdentifiers",
        "speechCustomVoiceNames", "speechRate", "speechVolume", "autoSpeakPolicy", "excludedBundleIDs", "replaceOriginal", "copyTranslation",
        "replaceShortcutKeyCode", "replaceShortcutModifiers", "copyShortcutKeyCode", "copyShortcutModifiers",
        "translationTiming", "translateShortcutKeyCode", "translateShortcutModifiers",
        "sourceLanguage", "targetLanguage", "translationBackend", "llmModels", "llmFallbackTimeout", "historyRetention",
    ]

    func testDisplayNamesAndRenamedBehaviorRawValue() {
        XCTAssertEqual(OverlayBehavior.stack.rawValue, "Stack Below")
        XCTAssertEqual(OverlayBehavior.replace.displayName(for: .chinese), "替换上一条")
        XCTAssertEqual(OverlayBehavior.stack.displayName(for: .chinese), "向下堆叠")
        XCTAssertEqual(OverlayBehavior.stack.displayName(for: .english), "Stack Below")
        XCTAssertEqual(OverlayPosition.topRight.displayName(for: .chinese), "右上")
        XCTAssertEqual(OverlayPosition.bottomCenter.displayName(for: .english), "Bottom Center")
        XCTAssertEqual(OverlayTextSize.small.displayName(for: .chinese), "小")
        XCTAssertEqual(OverlayTextSize.medium.displayName(for: .english), "Medium")
        XCTAssertEqual(L10n.groupSpeech(.chinese), "朗读")
        XCTAssertEqual(L10n.groupSpeech(.english), "Speech")
        XCTAssertEqual(L10n.readTranslationsAloud(.chinese), "朗读翻译结果")
        XCTAssertEqual(L10n.readTranslationsAloud(.english), "Read Translations Aloud")
        XCTAssertEqual(L10n.speechTimingAll(.chinese), "超时翻译、完整句子翻译和快捷键触发翻译")
        XCTAssertEqual(L10n.speechTimingPause(.english), "On Pause")
        XCTAssertEqual(L10n.speechTimingSummary([.pause, .shortcut], .chinese), "超时翻译、快捷键触发翻译")
        XCTAssertEqual(L10n.speechTimingSummary(.all, .english), "On Pause, Complete Sentence, and Shortcut")
        XCTAssertEqual(L10n.speechVoiceHint(.russian, .chinese), "朗读会使用此 Mac 上俄语的默认系统语音。")
        XCTAssertEqual(L10n.replaceOriginal(.chinese), "替换原文")
        XCTAssertEqual(L10n.replaceOriginal(.english), "Replace Original")
        XCTAssertEqual(L10n.copyTranslation(.chinese), "复制译文")
        XCTAssertEqual(L10n.copyTranslation(.english), "Copy Translation")
        XCTAssertEqual(L10n.replaceShortcut(.chinese), "替换快捷键")
        XCTAssertEqual(L10n.copyShortcut(.english), "Copy Shortcut")
        XCTAssertEqual(L10n.translationTiming(.chinese), "翻译时机")
        XCTAssertEqual(L10n.timingPause(.chinese), "超时翻译")
        XCTAssertEqual(L10n.timingCompleteSentence(.english), "Complete Sentence")
        XCTAssertEqual(L10n.timingShortcut(.chinese), "快捷键触发翻译")
        XCTAssertEqual(L10n.translateShortcut(.english), "Translate Shortcut")
        XCTAssertEqual(TranslationTiming.pause.displayName(for: .english), "On Pause")
        XCTAssertEqual(Language.chinese.speechLocaleIdentifier, "zh-CN")
        XCTAssertEqual(Language.english.speechLocaleIdentifier, "en-US")
        XCTAssertEqual(Language.japanese.speechLocaleIdentifier, "ja-JP")
        XCTAssertEqual(Language.russian.speechLocaleIdentifier, "ru-RU")
        XCTAssertEqual(Language.korean.speechLocaleIdentifier, "ko-KR")
        XCTAssertEqual(Language.french.speechLocaleIdentifier, "fr-FR")
        XCTAssertEqual(Language.german.speechLocaleIdentifier, "de-DE")
        XCTAssertEqual(Language.spanish.speechLocaleIdentifier, "es-ES")
        XCTAssertEqual(
            L10n.replaceOriginalHint(.chinese), "按下快捷键，把当前译文写回输入框。")
        XCTAssertEqual(
            L10n.replaceOriginalHint(.english), "Press the shortcut to replace the field with the current translation.")
        XCTAssertEqual(ReplaceShortcut.optionShiftLeftBracket.displayString, "⌥⇧[")
        XCTAssertEqual(ReplaceShortcut.optionShiftRightBracket.displayString, "⌥⇧]")
        XCTAssertFalse(ReplaceShortcut.optionShiftLeftBracket.displayString.contains("Key "))
        XCTAssertFalse(ReplaceShortcut.optionShiftRightBracket.displayString.contains("{"))
        XCTAssertFalse(ReplaceShortcut.optionShiftRightBracket.displayString.contains("}"))
        XCTAssertEqual(L10n.checkForUpdates(.chinese), "检查更新")
        XCTAssertEqual(L10n.checkForUpdates(.english), "Check for Updates")
        XCTAssertEqual(L10n.checkForUpdatesChecking(.chinese), "正在检查…")
        XCTAssertEqual(L10n.checkForUpdatesChecking(.english), "Checking…")
        XCTAssertEqual(L10n.checkForUpdatesUpToDate(.chinese), "已是最新版本")
        XCTAssertEqual(L10n.checkForUpdatesUpToDate(.english), "You’re up to date")
        XCTAssertEqual(L10n.historyRetentionName(.none, .chinese), "不记录")
        XCTAssertEqual(L10n.historyRetentionName(.none, .english), "Do Not Record")
        XCTAssertEqual(L10n.historyDelete(.chinese), "删除历史记录")
        XCTAssertEqual(L10n.historyDelete(.english), "Delete History")
        XCTAssertEqual(L10n.historyDeleteConfirmTitle(.chinese), "删除全部历史记录？")
        XCTAssertEqual(L10n.historyDeleteConfirmTitle(.english), "Delete All History?")
        XCTAssertEqual(L10n.historyDeleteConfirmMessage(.chinese), "将删除这台 Mac 上保存的全部翻译历史，此操作无法撤销。")
        XCTAssertEqual(
            L10n.historyDeleteConfirmMessage(.english),
            "This permanently deletes every saved translation on this Mac. This cannot be undone.")
        XCTAssertEqual(L10n.historyDeleteConfirm(.chinese), "删除全部")
        XCTAssertEqual(L10n.historyDeleteConfirm(.english), "Delete All")
        XCTAssertEqual(L10n.historyDeleteCancel(.chinese), "取消")
        XCTAssertEqual(L10n.historyDeleteCancel(.english), "Cancel")
        XCTAssertEqual(L10n.checkForUpdatesFailed(.chinese), "检查更新失败")
        XCTAssertEqual(L10n.checkForUpdatesFailed(.english), "Couldn’t check for updates")
        XCTAssertEqual(L10n.version(.chinese, marketing: "0.1.0"), "版本 0.1.0")
        XCTAssertEqual(L10n.version(.english, marketing: "0.1.0"), "Version 0.1.0")
    }

    func testMigratesLegacyHideAfterAndBehavior() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        defaults.set(false, forKey: "launchAtLogin")
        defaults.set(3.5, forKey: "hideAfter")
        defaults.set("Keep Previous", forKey: "overlayBehavior")
        defaults.set(true, forKey: "neverHide")

        let store = SettingsStore()
        XCTAssertEqual(store.hideAfter, 5)
        XCTAssertEqual(store.overlayBehavior, .stack)
        XCTAssertTrue(store.neverHide)
        XCTAssertEqual(defaults.double(forKey: "hideAfter"), 5)
        XCTAssertEqual(defaults.string(forKey: "overlayBehavior"), "Stack Below")
        XCTAssertTrue(defaults.bool(forKey: "neverHide"))
    }

    func testClampsHideAfterInDidSet() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        defaults.set(false, forKey: "launchAtLogin")
        defaults.set(12.0, forKey: "hideAfter")
        let store = SettingsStore()
        store.hideAfter = 3
        XCTAssertEqual(store.hideAfter, 5)
        XCTAssertEqual(defaults.double(forKey: "hideAfter"), 5)
        store.hideAfter = 90
        XCTAssertEqual(store.hideAfter, 60)
    }

    func testFreshDefaults() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        let store = SettingsStore()
        XCTAssertEqual(store.hideAfter, 5)
        XCTAssertFalse(store.neverHide)
        XCTAssertEqual(store.overlayBehavior, .replace)
        XCTAssertEqual(store.textSize, .medium)
        XCTAssertEqual(store.overlayPosition, .bottomCenter)
        XCTAssertEqual(store.overlayEdgeDistance, 48)
        XCTAssertTrue(store.enabled)
        XCTAssertFalse(store.launchAtLogin)
        XCTAssertEqual(store.uiLanguage, .chinese)
        XCTAssertFalse(store.speechEnabled)
        XCTAssertEqual(store.speechTriggers, [])
        XCTAssertFalse(store.replaceOriginal)
        XCTAssertFalse(store.copyTranslation)
        XCTAssertEqual(store.replaceShortcut, .optionShiftLeftBracket)
        XCTAssertEqual(store.copyShortcut, .optionShiftRightBracket)
        XCTAssertEqual(store.translationTiming, .pause)
        XCTAssertEqual(store.translateShortcut, .controlShiftT)
        XCTAssertEqual(store.sourceLanguage, .chinese)
        XCTAssertEqual(store.targetLanguage, .english)
        XCTAssertEqual(store.translationBackend, .local)
        XCTAssertEqual(store.llmFallbackTimeout, 8)
        XCTAssertEqual(store.historyRetention, .none)
        XCTAssertEqual(defaults.string(forKey: "historyRetention"), "none")
    }

    func testStoredHistoryRetentionIsKept() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set("7d", forKey: "historyRetention")
        let store = SettingsStore()
        XCTAssertEqual(store.historyRetention, .sevenDays)
        XCTAssertEqual(defaults.string(forKey: "historyRetention"), "7d")
    }

    func testUnknownHistoryRetentionFallsBackToNoneWithoutOverwriting() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set("bogus", forKey: "historyRetention")
        let store = SettingsStore()
        XCTAssertEqual(store.historyRetention, .none)
        XCTAssertEqual(defaults.string(forKey: "historyRetention"), "bogus")
    }

    func testTranslationDirectionAndBackendPersist() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")
        let store = SettingsStore()
        store.sourceLanguage = .english
        store.targetLanguage = .russian
        store.translationBackend = .languageModel
        store.llmFallbackTimeout = 12

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.sourceLanguage, .english)
        XCTAssertEqual(reloaded.targetLanguage, .russian)
        XCTAssertEqual(reloaded.translationBackend, .languageModel)
        XCTAssertEqual(reloaded.llmFallbackTimeout, 12)
    }

    func testUILanguagePersistsAndDefaultsToChinese() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        defaults.removeObject(forKey: "uiLanguage")
        defaults.set(false, forKey: "launchAtLogin")
        let store = SettingsStore()
        XCTAssertEqual(store.uiLanguage, .chinese)

        store.uiLanguage = .english
        XCTAssertEqual(defaults.string(forKey: "uiLanguage"), "en")

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.uiLanguage, .english)
    }

    func testTranslationSpeedPersistsAndInvalidValuesUseBalanced() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        defaults.set(700, forKey: "translationSpeed")
        let store = SettingsStore()
        XCTAssertEqual(store.translationSpeed, 700)
        store.translationSpeed = 300
        XCTAssertEqual(defaults.integer(forKey: "translationSpeed"), 300)

        defaults.set(999, forKey: "translationSpeed")
        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.translationSpeed, 450)
    }

    func testSpeechTriggersPersistAndLegacyVoiceKeysAreIgnored() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")
        defaults.set("en-GB", forKey: "speechVoiceIdentifier")
        defaults.set(0.35, forKey: "speechRate")
        defaults.set(0.65, forKey: "speechVolume")
        defaults.set("Always", forKey: "autoSpeakPolicy")

        let store = SettingsStore()
        XCTAssertFalse(store.speechEnabled)
        XCTAssertEqual(store.speechTriggers, [])
        XCTAssertEqual(store.translationTiming, .pause)
        XCTAssertEqual(defaults.string(forKey: "speechVoiceIdentifier"), "en-GB")
        XCTAssertEqual(defaults.double(forKey: "speechRate"), 0.35)
        XCTAssertEqual(defaults.double(forKey: "speechVolume"), 0.65)
        XCTAssertEqual(defaults.string(forKey: "autoSpeakPolicy"), "Always")

        store.speechTriggers = [.pause, .shortcut]
        XCTAssertTrue(store.speechEnabled)

        let reloaded = SettingsStore()
        XCTAssertTrue(reloaded.speechEnabled)
        XCTAssertEqual(reloaded.speechTriggers, [.pause, .shortcut])
        XCTAssertEqual(reloaded.translationTiming, .pause)
        XCTAssertEqual(defaults.string(forKey: "speechVoiceIdentifier"), "en-GB")
        XCTAssertEqual(defaults.double(forKey: "speechRate"), 0.35)
        XCTAssertEqual(defaults.double(forKey: "speechVolume"), 0.65)
        XCTAssertEqual(defaults.string(forKey: "autoSpeakPolicy"), "Always")
    }

    func testLegacyEnabledSpeechMigratesToCompletedAndShortcutChoices() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")
        defaults.set(true, forKey: "speechEnabled")

        let store = SettingsStore()
        XCTAssertTrue(store.speechEnabled)
        XCTAssertEqual(store.speechTriggers, [.completeSentence, .shortcut])
        XCTAssertEqual(defaults.integer(forKey: "speechTriggers"), 6)
    }

    func testReplaceAndCopySettingsPersistAndMissingKeysDefaultSafely() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(12.0, forKey: "hideAfter")
        defaults.set(false, forKey: "launchAtLogin")
        defaults.set(true, forKey: "speechEnabled")
        let store = SettingsStore()
        XCTAssertFalse(store.replaceOriginal)
        XCTAssertFalse(store.copyTranslation)
        XCTAssertEqual(store.replaceShortcut, .optionShiftLeftBracket)
        XCTAssertEqual(store.copyShortcut, .optionShiftRightBracket)
        XCTAssertEqual(store.translationTiming, .pause)
        XCTAssertEqual(store.translateShortcut, .controlShiftT)
        XCTAssertEqual(store.hideAfter, 12)
        XCTAssertTrue(store.speechEnabled)
        XCTAssertEqual(store.speechTriggers, [.completeSentence, .shortcut])

        store.replaceOriginal = true
        store.copyTranslation = true
        store.replaceShortcut = ReplaceShortcut(
            keyCode: ReplaceShortcut.cKeyCode,
            carbonModifiers: ReplaceShortcut.controlKeyFlag | ReplaceShortcut.optionKeyFlag)
        store.copyShortcut = ReplaceShortcut(
            keyCode: ReplaceShortcut.returnKeyCode,
            carbonModifiers: ReplaceShortcut.controlKeyFlag | ReplaceShortcut.commandKeyFlag)
        store.translationTiming = .completeSentence
        store.translateShortcut = ReplaceShortcut(
            keyCode: ReplaceShortcut.tKeyCode,
            carbonModifiers: ReplaceShortcut.controlKeyFlag | ReplaceShortcut.commandKeyFlag)

        let reloaded = SettingsStore()
        XCTAssertTrue(reloaded.replaceOriginal)
        XCTAssertTrue(reloaded.copyTranslation)
        XCTAssertEqual(reloaded.replaceShortcut.keyCode, ReplaceShortcut.cKeyCode)
        XCTAssertEqual(
            reloaded.replaceShortcut.carbonModifiers, ReplaceShortcut.controlKeyFlag | ReplaceShortcut.optionKeyFlag)
        XCTAssertEqual(reloaded.copyShortcut.keyCode, ReplaceShortcut.returnKeyCode)
        XCTAssertEqual(
            reloaded.copyShortcut.carbonModifiers, ReplaceShortcut.controlKeyFlag | ReplaceShortcut.commandKeyFlag)
        XCTAssertEqual(reloaded.translationTiming, .completeSentence)
        XCTAssertEqual(reloaded.translateShortcut.keyCode, ReplaceShortcut.tKeyCode)
        XCTAssertEqual(
            reloaded.translateShortcut.carbonModifiers,
            ReplaceShortcut.controlKeyFlag | ReplaceShortcut.commandKeyFlag)
        XCTAssertEqual(reloaded.hideAfter, 12)
        XCTAssertTrue(reloaded.speechEnabled)
        XCTAssertEqual(reloaded.speechTriggers, [.completeSentence, .shortcut])
    }

    func testMissingTimingDefaultsWithoutChangingReplaceCopy() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(true, forKey: "replaceOriginal")
        defaults.set(true, forKey: "copyTranslation")
        defaults.set(Int(ReplaceShortcut.cKeyCode), forKey: "replaceShortcutKeyCode")
        defaults.set(
            Int(ReplaceShortcut.controlKeyFlag | ReplaceShortcut.optionKeyFlag),
            forKey: "replaceShortcutModifiers")
        defaults.set(false, forKey: "launchAtLogin")

        let store = SettingsStore()
        XCTAssertTrue(store.replaceOriginal)
        XCTAssertTrue(store.copyTranslation)
        XCTAssertEqual(store.replaceShortcut.keyCode, ReplaceShortcut.cKeyCode)
        XCTAssertEqual(
            store.replaceShortcut.carbonModifiers, ReplaceShortcut.controlKeyFlag | ReplaceShortcut.optionKeyFlag)
        XCTAssertNotEqual(store.replaceShortcut, .optionShiftLeftBracket)
        XCTAssertEqual(store.copyShortcut, .optionShiftRightBracket)
        XCTAssertEqual(store.translationTiming, .pause)
        XCTAssertEqual(store.translateShortcut, .controlShiftT)
    }

    func testSpeechVoicesPersistIndependentlyForEachLanguage() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")

        let store = SettingsStore()
        XCTAssertNil(store.configuredSpeechVoice(for: .chinese))

        store.setSpeechVoiceIdentifier("com.apple.voice.enhanced.en-US.Zoe", for: .english)
        store.setSpeechVoiceIdentifier("com.apple.voice.enhanced.zh-CN.Lilian", for: .chinese)
        store.setSpeechVoiceIdentifier("com.apple.voice.enhanced.ru-RU.Milena", for: .russian)

        let reloaded = SettingsStore()
        XCTAssertEqual(reloaded.configuredSpeechVoice(for: .english), "com.apple.voice.enhanced.en-US.Zoe")
        XCTAssertEqual(reloaded.configuredSpeechVoice(for: .chinese), "com.apple.voice.enhanced.zh-CN.Lilian")
        XCTAssertEqual(reloaded.configuredSpeechVoice(for: .russian), "com.apple.voice.enhanced.ru-RU.Milena")
        XCTAssertNil(reloaded.configuredSpeechVoice(for: .japanese))

        reloaded.setSpeechVoiceIdentifier("catalog-japanese", for: .japanese)
        XCTAssertEqual(reloaded.configuredSpeechVoice(for: .japanese), "catalog-japanese")
    }

    func testLocalBackendDoesNotReadKeychainUntilLanguageModelIsSelected() throws {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")

        let modelID = UUID()
        let model = LLMModelConfiguration(
            id: modelID, name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", model: "deepseek-chat")
        defaults.set(try JSONEncoder().encode([model]), forKey: "llmModels")

        let keychain = InMemoryAPIKeyStore()
        try keychain.setAPIKey("sk-secret", forModelID: modelID)

        let store = SettingsStore(keychain: keychain)
        XCTAssertEqual(store.translationBackend, .local)
        XCTAssertEqual(store.llmModels.first?.apiKey, "")
        XCTAssertEqual(keychain.readIDs, [])
        XCTAssertEqual(keychain.deleteIDs, [])
        XCTAssertEqual(keychain.storedKey(for: modelID), "sk-secret")

        store.translationBackend = .languageModel
        XCTAssertEqual(store.llmModels.first?.apiKey, "sk-secret")
        XCTAssertEqual(keychain.readIDs, [modelID])
        XCTAssertEqual(keychain.storedKey(for: modelID), "sk-secret")
    }

    func testLanguageModelBackendLoadsKeychainKeysOnLaunch() throws {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")
        defaults.set(TranslationBackend.languageModel.rawValue, forKey: "translationBackend")

        let modelID = UUID()
        let model = LLMModelConfiguration(
            id: modelID, name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", model: "deepseek-chat")
        defaults.set(try JSONEncoder().encode([model]), forKey: "llmModels")

        let keychain = InMemoryAPIKeyStore()
        try keychain.setAPIKey("sk-on-launch", forModelID: modelID)

        let store = SettingsStore(keychain: keychain)
        XCTAssertEqual(store.translationBackend, .languageModel)
        XCTAssertEqual(store.llmModels.first?.apiKey, "sk-on-launch")
        XCTAssertEqual(keychain.readIDs, [modelID])
    }

    private func snapshot(_ defaults: UserDefaults) -> [String: Any?] {
        Dictionary(uniqueKeysWithValues: keys.map { ($0, defaults.object(forKey: $0)) })
    }

    private func restore(_ defaults: UserDefaults, _ saved: [String: Any?]) {
        for key in keys {
            if let value = saved[key], !(value is NSNull) {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}

private final class InMemoryAPIKeyStore: APIKeyStore, @unchecked Sendable {
    private var keys: [UUID: String] = [:]
    private(set) var readIDs: [UUID] = []
    private(set) var deleteIDs: [UUID] = []

    func setAPIKey(_ value: String?, forModelID id: UUID) throws {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            keys.removeValue(forKey: id)
        } else {
            keys[id] = trimmed
        }
    }

    func apiKey(forModelID id: UUID) throws -> String? {
        readIDs.append(id)
        return keys[id]
    }

    func deleteAPIKey(forModelID id: UUID) throws {
        deleteIDs.append(id)
        keys.removeValue(forKey: id)
    }

    func storedKey(for id: UUID) -> String? {
        keys[id]
    }
}

final class SpeechPolicyEvaluatorTests: XCTestCase {
    private let evaluator = SpeechPolicyEvaluator()

    func testDisabledIsSilentInEveryMode() {
        for timing in TranslationTiming.allCases {
            XCTAssertFalse(
                evaluator.shouldSpeak(speechEnabled: false, speechTriggers: .all, translationTiming: timing),
                "disabled auto-speak must stay silent in \(timing.rawValue)")
        }
    }

    func testSelectedPauseSpeaks() {
        XCTAssertTrue(evaluator.shouldSpeak(speechEnabled: true, speechTriggers: [.pause], translationTiming: .pause))
        XCTAssertFalse(
            evaluator.shouldSpeak(
                speechEnabled: true, speechTriggers: [.pause], translationTiming: .completeSentence))
    }

    func testSelectedCompleteSentenceSpeaks() {
        XCTAssertTrue(
            evaluator.shouldSpeak(
                speechEnabled: true, speechTriggers: [.completeSentence], translationTiming: .completeSentence))
        XCTAssertFalse(evaluator.shouldSpeak(speechEnabled: true, speechTriggers: [], translationTiming: .completeSentence))
    }

    func testAllSelectedSpeaksForEveryTiming() {
        XCTAssertTrue(evaluator.shouldSpeak(speechEnabled: true, speechTriggers: .all, translationTiming: .pause))
        XCTAssertTrue(
            evaluator.shouldSpeak(
                speechEnabled: true, speechTriggers: .all, translationTiming: .completeSentence))
        XCTAssertTrue(evaluator.shouldSpeak(speechEnabled: true, speechTriggers: .all, translationTiming: .shortcut))
    }
}

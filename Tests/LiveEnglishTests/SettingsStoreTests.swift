import XCTest

@testable import LiveEnglish

@MainActor
final class SettingsStoreTests: XCTestCase {
    private let keys = [
        "enabled", "hideAfter", "neverHide", "launchAtLogin", "textSize", "overlayPosition", "overlayEdgeDistance",
        "overlayBehavior", "uiLanguage", "translationSpeed", "speechEnabled", "speechVoiceIdentifier", "speechRate",
        "speechVolume", "autoSpeakPolicy", "excludedBundleIDs",
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
        XCTAssertEqual(AutoSpeakPolicy.quietOnly.displayName(for: .chinese), "仅在 Mac 安静时")
        XCTAssertEqual(AutoSpeakPolicy.always.displayName(for: .english), "Always")
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
        XCTAssertEqual(store.speechVoiceIdentifier, "en-US")
        XCTAssertEqual(store.speechRate, 0.5)
        XCTAssertEqual(store.speechVolume, 0.8)
        XCTAssertEqual(store.autoSpeakPolicy, .quietOnly)
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

    func testSpeechSettingsPersistAndInvalidValuesNormalize() {
        let defaults = UserDefaults.standard
        let saved = snapshot(defaults)
        defer { restore(defaults, saved) }

        for key in keys { defaults.removeObject(forKey: key) }
        defaults.set(false, forKey: "launchAtLogin")
        defaults.set("", forKey: "speechVoiceIdentifier")
        defaults.set(4.0, forKey: "speechRate")
        defaults.set(-1.0, forKey: "speechVolume")
        defaults.set("Mystery", forKey: "autoSpeakPolicy")

        let store = SettingsStore()
        XCTAssertFalse(store.speechEnabled)
        XCTAssertEqual(store.speechVoiceIdentifier, "en-US")
        XCTAssertEqual(store.speechRate, 1.0)
        XCTAssertEqual(store.speechVolume, 0.0)
        XCTAssertEqual(store.autoSpeakPolicy, .quietOnly)

        store.speechEnabled = true
        store.speechVoiceIdentifier = "en-GB"
        store.speechRate = 0.35
        store.speechVolume = 0.65
        store.autoSpeakPolicy = .always

        let reloaded = SettingsStore()
        XCTAssertTrue(reloaded.speechEnabled)
        XCTAssertEqual(reloaded.speechVoiceIdentifier, "en-GB")
        XCTAssertEqual(reloaded.speechRate, 0.35)
        XCTAssertEqual(reloaded.speechVolume, 0.65)
        XCTAssertEqual(reloaded.autoSpeakPolicy, .always)
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

final class SpeechPolicyEvaluatorTests: XCTestCase {
    private let evaluator = SpeechPolicyEvaluator()

    func testSpeechDisabledOverridesPolicy() {
        XCTAssertFalse(
            evaluator.shouldSpeak(speechEnabled: false, autoSpeakPolicy: .always, audioContext: .silent))
    }

    func testQuietOnlySpeaksOnlyWhenSilent() {
        XCTAssertTrue(
            evaluator.shouldSpeak(speechEnabled: true, autoSpeakPolicy: .quietOnly, audioContext: .silent))
        XCTAssertFalse(
            evaluator.shouldSpeak(speechEnabled: true, autoSpeakPolicy: .quietOnly, audioContext: .mediaPlayback))
        XCTAssertFalse(
            evaluator.shouldSpeak(speechEnabled: true, autoSpeakPolicy: .quietOnly, audioContext: .communication))
        XCTAssertFalse(
            evaluator.shouldSpeak(speechEnabled: true, autoSpeakPolicy: .quietOnly, audioContext: .unknownAudio))
    }

    func testAlwaysAndNeverPolicies() {
        XCTAssertTrue(
            evaluator.shouldSpeak(speechEnabled: true, autoSpeakPolicy: .always, audioContext: .communication))
        XCTAssertFalse(
            evaluator.shouldSpeak(speechEnabled: true, autoSpeakPolicy: .never, audioContext: .silent))
    }
}

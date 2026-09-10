import AVFoundation
import CoreAudio
import Foundation

enum AudioContext: Equatable, Sendable {
    case silent
    case mediaPlayback
    case communication
    case unknownAudio
}

protocol AudioContextDetecting: Sendable {
    func currentContext() -> AudioContext
}

@MainActor protocol SpeechPerforming: AnyObject {
    func speak(_ text: String, language: Language)
    func speak(_ text: String, language: Language, voiceIdentifier: String?)
    func stop()
}

extension SpeechPerforming {
    func speak(_ text: String, language: Language) {
        speak(text, language: language, voiceIdentifier: nil)
    }
}

struct SpeechPolicyEvaluator: Sendable {
    func shouldSpeak(
        speechEnabled: Bool,
        speechTriggers: SpeechTriggerSelection,
        event: TranslationEvent
    ) -> Bool {
        speechEnabled && speechTriggers.contains(SpeechTriggerSelection(timing: event.timing))
    }

    func shouldSpeak(
        speechEnabled: Bool,
        speechTriggers: SpeechTriggerSelection,
        translationTiming: TranslationTiming
    ) -> Bool {
        shouldSpeak(
            speechEnabled: speechEnabled,
            speechTriggers: speechTriggers,
            event: TranslationEvent(timing: translationTiming))
    }
}

extension TranslationEvent {
    init(timing: TranslationTiming) {
        switch timing {
        case .pause: self = .pause
        case .completeSentence: self = .completeSentence
        case .shortcut: self = .shortcut
        }
    }
}

@MainActor final class SpeechService: NSObject, SpeechPerforming, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: Language) {
        speak(text, language: language, voiceIdentifier: nil)
    }

    func speak(_ text: String, language: Language, voiceIdentifier: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let synthesizer = synthesizer
        let voice = preferredVoice(for: language, override: voiceIdentifier)
        // Leave the Swift Task so AXCoreUtilities does not unsafeForcedSync from a concurrent job.
        DispatchQueue.main.async {
            synthesizer.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: trimmed)
            utterance.voice = voice
            utterance.rate = 0.5
            utterance.volume = 1.0
            synthesizer.speak(utterance)
        }
    }

    /// Prefer an explicitly selected or user-entered voice, then use macOS's
    /// default voice for the target language. Invalid custom values safely
    /// fall back to the system voice instead of speaking the wrong language.
    private func preferredVoice(for language: Language, override: String?) -> AVSpeechSynthesisVoice? {
        if let override, let voice = SpeechVoiceCatalog.voice(matching: override, for: language) {
            return voice
        }
        return systemVoice(for: language)
    }

    private func systemVoice(for language: Language) -> AVSpeechSynthesisVoice? {
        if let defaultVoice = AVSpeechSynthesisVoice(language: language.speechLocaleIdentifier) {
            return defaultVoice
        }
        return SpeechVoiceCatalog.options(for: language).first.flatMap {
            AVSpeechSynthesisVoice(identifier: $0.identifier)
        }
    }

    func stop() {
        let synthesizer = synthesizer
        DispatchQueue.main.async {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}

enum SpeechVoiceQuality: String, Sendable {
    case standard
    case enhanced
    case premium

    var sortRank: Int {
        switch self {
        case .premium: return 0
        case .enhanced: return 1
        case .standard: return 2
        }
    }

    func displayName(for language: UILanguage) -> String {
        switch self {
        case .standard: return language == .chinese ? "标准音质" : "Standard"
        case .enhanced: return language == .chinese ? "优化音质" : "Enhanced"
        case .premium: return language == .chinese ? "高音质" : "Premium"
        }
    }
}

struct SpeechVoiceOption: Identifiable, Hashable, Sendable {
    let identifier: String
    let name: String
    let languageIdentifier: String
    let quality: SpeechVoiceQuality

    var id: String { identifier }

    func displayName(for language: UILanguage) -> String {
        "\(SpeechVoiceCatalog.localizedName(for: self, language: language)) · \(languageIdentifier) (\(quality.displayName(for: language)))"
    }
}

enum SpeechVoiceCatalog {
    static func options(for language: Language) -> [SpeechVoiceOption] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { matches($0, language: language) }
            .map {
                let quality: SpeechVoiceQuality
                switch $0.quality {
                case .premium: quality = .premium
                case .enhanced: quality = .enhanced
                default: quality = .standard
                }
                return SpeechVoiceOption(
                    identifier: $0.identifier,
                    name: $0.name,
                    languageIdentifier: $0.language,
                    quality: quality)
            }
            .sorted {
                if $0.quality != $1.quality { return $0.quality.sortRank < $1.quality.sortRank }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    static func voice(matching value: String, for language: Language) -> AVSpeechSynthesisVoice? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { matches($0, language: language) }
        if let voice = voices.first(where: { $0.identifier.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return voice
        }
        let normalized = normalizedName(trimmed)
        return voices
            .filter {
                normalizedName($0.name) == normalized
                    || normalizedName(localizedName(for: $0)) == normalized
            }
            .sorted { qualityRank($0) < qualityRank($1) }
            .first
    }

    static func localizedName(for option: SpeechVoiceOption, language: UILanguage) -> String {
        if language == .chinese,
           option.identifier.caseInsensitiveCompare("com.apple.voice.premium.zh-CN.Lilian") == .orderedSame {
            return "黎潋"
        }
        return baseDisplayName(option.name)
    }

    private static func localizedName(for voice: AVSpeechSynthesisVoice) -> String {
        if voice.identifier.caseInsensitiveCompare("com.apple.voice.premium.zh-CN.Lilian") == .orderedSame {
            return "黎潋"
        }
        return voice.name
    }

    private static func normalizedName(_ value: String, removeQualitySuffix: Bool = true) -> String {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard removeQualitySuffix else { return result }
        let suffixes = ["(premium)", "(enhanced)", "(standard)", "（高音质）", "（优化音质）", "（标准音质）"]
        for suffix in suffixes where result.hasSuffix(suffix) {
            result.removeLast(suffix.count)
            break
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func baseDisplayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let suffixes = [" (premium)", " (enhanced)", " (standard)", "（高音质）", "（优化音质）", "（标准音质）"]
        for suffix in suffixes where lowercased.hasSuffix(suffix) {
            return String(trimmed.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    private static func qualityRank(_ voice: AVSpeechSynthesisVoice) -> Int {
        switch voice.quality {
        case .premium: return 0
        case .enhanced: return 1
        default: return 2
        }
    }

    static func matches(_ voice: AVSpeechSynthesisVoice, language: Language) -> Bool {
        let identifier = voice.language.replacingOccurrences(of: "_", with: "-").lowercased()
        let base = identifier.split(separator: "-").first.map(String.init) ?? identifier
        return base == language.rawValue.lowercased()
    }
}

struct SystemAudioContextDetector: AudioContextDetecting {
    private let currentPID: pid_t
    private let communicationBundleIDs: Set<String>

    init(
        currentPID: pid_t = ProcessInfo.processInfo.processIdentifier,
        communicationBundleIDs: Set<String> = [
            "us.zoom.xos",
            "com.microsoft.teams2",
            "com.microsoft.teams",
            "com.google.Chrome",
            "com.tencent.meeting",
            "com.ss.lark",
            "com.tinyspeck.slackmacgap",
            "com.hnc.Discord",
        ]
    ) {
        self.currentPID = currentPID
        self.communicationBundleIDs = communicationBundleIDs
    }

    func currentContext() -> AudioContext {
        if let processContext = processAudioContext() {
            return processContext
        }
        return defaultOutputDeviceIsRunning() ? .unknownAudio : .silent
    }

    private func processAudioContext() -> AudioContext? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        guard sizeStatus == noErr, dataSize > 0 else { return nil }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processIDs = Array(repeating: AudioObjectID(kAudioObjectUnknown), count: count)
        let status = processIDs.withUnsafeMutableBytes { buffer in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, buffer.baseAddress!)
        }
        guard status == noErr else { return nil }

        var sawOutput = false
        var sawUnknown = false
        for processObjectID in processIDs {
            guard processObjectID != kAudioObjectUnknown else { continue }
            guard let info = processInfo(for: processObjectID), info.pid != currentPID else { continue }
            let inputActive = info.isRunningInput == 1
            let outputActive = info.isRunningOutput == 1
            if inputActive && outputActive { return .communication }
            if outputActive, let bundleID = info.bundleID, communicationBundleIDs.contains(bundleID) {
                return .communication
            }
            if outputActive { sawOutput = true }
            if info.isRunning == nil || info.isRunningInput == nil || info.isRunningOutput == nil { sawUnknown = true }
        }

        if sawOutput { return .mediaPlayback }
        if sawUnknown { return .unknownAudio }
        return .silent
    }

    private func processInfo(for objectID: AudioObjectID) -> ProcessAudioInfo? {
        let pidValue = readUInt32Property(objectID, selector: kAudioProcessPropertyPID)
        let bundleID: String? = readCFStringProperty(objectID, selector: kAudioProcessPropertyBundleID) as String?
        return ProcessAudioInfo(
            pid: pidValue.map { pid_t($0) } ?? -1,
            bundleID: bundleID,
            isRunning: readUInt32Property(objectID, selector: kAudioProcessPropertyIsRunning),
            isRunningInput: readUInt32Property(objectID, selector: kAudioProcessPropertyIsRunningInput),
            isRunningOutput: readUInt32Property(objectID, selector: kAudioProcessPropertyIsRunningOutput))
    }

    private func defaultOutputDeviceIsRunning() -> Bool {
        guard let outputDevice = readUInt32Property(
            AudioObjectID(kAudioObjectSystemObject), selector: kAudioHardwarePropertyDefaultOutputDevice),
            outputDevice != kAudioObjectUnknown
        else { return false }
        let running = readUInt32Property(outputDevice, selector: kAudioDevicePropertyDeviceIsRunningSomewhere)
        return running == 1
    }

    private func readUInt32Property(_ objectID: AudioObjectID, selector: AudioObjectPropertySelector) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var value: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else { return nil }
        return value
    }

    private func readCFStringProperty(_ objectID: AudioObjectID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, &value)
        guard status == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }

    private struct ProcessAudioInfo {
        let pid: pid_t
        let bundleID: String?
        let isRunning: UInt32?
        let isRunningInput: UInt32?
        let isRunningOutput: UInt32?
    }
}

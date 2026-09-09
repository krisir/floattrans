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
    func stop()
}

struct SpeechPolicyEvaluator: Sendable {
    func shouldSpeak(
        speechEnabled: Bool,
        speechTriggers: SpeechTriggerSelection,
        translationTiming: TranslationTiming
    ) -> Bool {
        let normalizedTriggers = SpeechTriggerSelection.normalized(rawValue: speechTriggers.rawValue)
        return speechEnabled && normalizedTriggers.contains(SpeechTriggerSelection(timing: translationTiming))
    }
}

@MainActor final class SpeechService: NSObject, SpeechPerforming, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: Language) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let synthesizer = synthesizer
        let voice = systemVoice(for: language)
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

    /// Prefer macOS's default voice for the selected target language. If its
    /// exact regional variant is not installed, use another installed voice
    /// for that language before allowing AVFoundation to choose a fallback.
    private func systemVoice(for language: Language) -> AVSpeechSynthesisVoice? {
        if let defaultVoice = AVSpeechSynthesisVoice(language: language.speechLocaleIdentifier) {
            return defaultVoice
        }
        let languagePrefix = language.rawValue + "-"
        return AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == language.rawValue || $0.language.hasPrefix(languagePrefix)
        }
    }

    func stop() {
        let synthesizer = synthesizer
        DispatchQueue.main.async {
            synthesizer.stopSpeaking(at: .immediate)
        }
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

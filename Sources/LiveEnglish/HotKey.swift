import Carbon
import Foundation

enum TranslationHotKeyAction: UInt32, CaseIterable {
    case replace = 1
    case copy = 2
    case translate = 3
}

@MainActor
final class GlobalHotKey {
    static let shared = GlobalHotKey()
    private static let signature: OSType = 0x46544143  // 'FTAC'
    var onAction: ((TranslationHotKeyAction) -> Void)?
    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var handler: EventHandlerRef?

    func set(_ action: TranslationHotKeyAction, shortcut: ReplaceShortcut?) {
        unregister(action)
        guard let shortcut else { return }
        installHandlerIfNeeded()
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: action.rawValue)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef)
        if status == noErr, let hotKeyRef {
            refs[action.rawValue] = hotKeyRef
        }
    }

    func unregister(_ action: TranslationHotKeyAction) {
        if let ref = refs.removeValue(forKey: action.rawValue) {
            UnregisterEventHotKey(ref)
        }
    }

    func unregisterAll() {
        for action in TranslationHotKeyAction.allCases { unregister(action) }
    }

    private func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return noErr }
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID)
                let owner = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                if let action = TranslationHotKeyAction(rawValue: hotKeyID.id) {
                    DispatchQueue.main.async {
                        MainActor.assumeIsolated {
                            owner.onAction?(action)
                        }
                    }
                }
                return noErr
            },
            1,
            &eventType,
            userData,
            &handler)
    }
}

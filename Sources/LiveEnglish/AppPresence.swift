import AppKit

/// Maps Settings and Welcome chrome to Dock / Cmd+Tab presence.
/// Overlay panels and the translation-host panel are ignored by never being passed in.
@MainActor
enum AppPresence {
    static func countsAsChrome(isVisible: Bool, isMiniaturized: Bool) -> Bool {
        isVisible || isMiniaturized
    }

    static func countsAsChrome(_ window: NSWindow?) -> Bool {
        guard let window else { return false }
        return countsAsChrome(isVisible: window.isVisible, isMiniaturized: window.isMiniaturized)
    }

    static func activationPolicy(settingsPresent: Bool, welcomePresent: Bool) -> NSApplication.ActivationPolicy {
        (settingsPresent || welcomePresent) ? .regular : .accessory
    }

    static func activationPolicy(
        settings: NSWindow?,
        welcome: NSWindow?,
        closing: NSWindow? = nil
    ) -> NSApplication.ActivationPolicy {
        activationPolicy(
            settingsPresent: settings !== closing && countsAsChrome(settings),
            welcomePresent: welcome !== closing && countsAsChrome(welcome)
        )
    }

    static func windowToReopen(settings: NSWindow?, welcome: NSWindow?) -> NSWindow? {
        if countsAsChrome(settings) { return settings }
        if countsAsChrome(welcome) { return welcome }
        return nil
    }

    static func reveal(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
    }

    static func apply(_ policy: NSApplication.ActivationPolicy) {
        guard NSApp.activationPolicy() != policy else { return }
        NSApp.setActivationPolicy(policy)
    }
}

@MainActor
final class ChromeWindowObserver: NSObject, NSWindowDelegate {
    var onClose: ((NSWindow) -> Void)?
    var onMiniaturizeChange: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        onClose?(window)
    }

    func windowDidMiniaturize(_ notification: Notification) {
        onMiniaturizeChange?()
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        onMiniaturizeChange?()
    }
}

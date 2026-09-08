@preconcurrency import AppKit
@preconcurrency import ApplicationServices
@preconcurrency import Foundation
import OSLog

public struct InputSessionID: Hashable, Sendable {
    public let pid: pid_t
    public let token: UUID
    public init(pid: pid_t, token: UUID = UUID()) {
        self.pid = pid
        self.token = token
    }
}

@MainActor final class InputDebouncer {
    private var task: Task<Void, Never>?
    var delay: Duration = .milliseconds(450)
    func submit(_ snapshot: TextSnapshot, action: @escaping @MainActor (TextSnapshot) -> Void) {
        task?.cancel()
        task = Task { [delay] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            action(snapshot)
        }
    }
    func cancel() {
        task?.cancel()
        task = nil
    }
}

@MainActor final class InputCoordinator {
    private let logger = Logger(subsystem: "com.liveenglish.app", category: "pipeline")
    private let extractor = SentenceExtractor(), detector = LanguageTextDetector(), debouncer = InputDebouncer()
    private var lastSentence = "", session: InputSessionID?
    var isEnabled = true
    var sourceLanguage: Language = .chinese
    var excludedBundleIDs: Set<String> = []
    var delayMilliseconds: Int {
        get {
            Int(
                debouncer.delay.components.seconds * 1000 + debouncer.delay.components.attoseconds
                    / 1_000_000_000_000_000)
        }
        set { debouncer.delay = .milliseconds(newValue) }
    }
    var timing: TranslationTiming = .pause {
        didSet {
            if timing != .pause { debouncer.cancel() }
        }
    }
    var onSentence: ((String, String, InputSessionID, NSScreen?, TextSnapshot) -> Void)?, onEmpty: (() -> Void)?
    func setSourceLanguage(_ language: Language) {
        sourceLanguage = language
        reset()
    }
    func handle(_ snapshot: TextSnapshot, session: InputSessionID, screen: NSScreen?) {
        DiagnosticLog.write(
            "snapshot received bundle=\(snapshot.bundleIdentifier ?? "unknown") length=\(snapshot.text.count)")
        logger.info(
            "snapshot received bundle=\(snapshot.bundleIdentifier ?? "unknown", privacy: .public) length=\(snapshot.text.count, privacy: .public)"
        )
        guard isEnabled else { return }
        if excludedBundleIDs.contains(snapshot.bundleIdentifier ?? "") {
            logger.info("snapshot ignored excluded app")
            reset()
            return
        }
        self.session = session
        if snapshot.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            debouncer.cancel()
            lastSentence = ""
            onEmpty?()
            return
        }
        switch timing {
        case .pause:
            debouncer.submit(snapshot) { [weak self] snapshot in
                guard let self, self.session == session else { return }
                self.emit(snapshot, session: session, screen: screen)
            }
        case .completeSentence:
            debouncer.cancel()
            if extractor.isComplete(snapshot) {
                emit(snapshot, session: session, screen: screen)
            }
        case .shortcut:
            debouncer.cancel()
        }
    }
    func translateNow(_ snapshot: TextSnapshot, session: InputSessionID, screen: NSScreen?) {
        guard isEnabled else { return }
        self.session = session
        emit(snapshot, session: session, screen: screen, force: true)
    }
    func reset() {
        debouncer.cancel()
        session = nil
        lastSentence = ""
        onEmpty?()
    }

    private func emit(
        _ snapshot: TextSnapshot, session: InputSessionID, screen: NSScreen?, force: Bool = false
    ) {
        let sentence = extractor.extract(from: snapshot)
        DiagnosticLog.write(
            "debounce fired sentenceLength=\(sentence.count) source=\(sourceLanguage.rawValue) matches=\(detector.contains(sentence, language: sourceLanguage))")
        logger.info(
            "debounce fired sentenceLength=\(sentence.count, privacy: .public) source=\(self.sourceLanguage.rawValue, privacy: .public) matches=\(self.detector.contains(sentence, language: self.sourceLanguage), privacy: .public)"
        )
        guard !sentence.isEmpty, detector.contains(sentence, language: sourceLanguage) else { return }
        if !force, sentence == lastSentence { return }
        lastSentence = sentence
        let nsText = snapshot.text as NSString
        let sentenceRange = nsText.range(of: sentence, options: .backwards)
        let sentenceKey =
            sentenceRange.location == NSNotFound
            ? "\(session.token.uuidString):\(sentence)" : nsText.substring(to: sentenceRange.location)
        onSentence?(sentence, sentenceKey, session, screen, snapshot)
    }
}

@MainActor final class AccessibilityMonitor {
    private let logger = Logger(subsystem: "com.liveenglish.app", category: "accessibility")
    var onSnapshot: ((TextSnapshot, InputSessionID, NSScreen?) -> Void)?
    var excludedBundleIDs: Set<String> = []
    var sourceLanguage: Language = .chinese
    var onFocusChanged: (() -> Void)?
    private var appObserver: NSObjectProtocol?, elementObserver: AXObserver?, pollTimer: Timer?, focused: AXUIElement?,
        lastText: String?, lastGoodText: String?, lastSelectedRange: NSRange?, session = InputSessionID(pid: 0)
    private var focusedApp: AXUIElement?
    private(set) var isRunning = false
    func start() {
        guard AXIsProcessTrusted() else {
            DiagnosticLog.write("AX trust check failed")
            NSLog("LiveEnglish AX trust check failed")
            logger.error("AX trust check failed")
            return
        }
        guard !isRunning else { return }
        isRunning = true
        DiagnosticLog.write("monitor starting")
        NSLog("LiveEnglish monitor starting")
        logger.info("monitor starting")
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in self?.focusApplication(NSWorkspace.shared.frontmostApplication) }
        }
        focusApplication(NSWorkspace.shared.frontmostApplication)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.readSnapshot() }
        }
    }
    func stop() {
        if let appObserver { NSWorkspace.shared.notificationCenter.removeObserver(appObserver) }
        appObserver = nil
        pollTimer?.invalidate()
        pollTimer = nil
        removeObserver()
        isRunning = false
    }
    private func focusApplication(_ app: NSRunningApplication?) {
        guard let app else { return }
        removeObserver()
        let pid = app.processIdentifier
        session = InputSessionID(pid: pid)
        DiagnosticLog.write("focused app pid=\(pid) bundle=\(app.bundleIdentifier ?? "unknown")")
        logger.info(
            "focused app pid=\(pid, privacy: .public) bundle=\(app.bundleIdentifier ?? "unknown", privacy: .public)")
        onFocusChanged?()
        let appElement = AXUIElementCreateApplication(pid)
        focusedApp = appElement
        observe(appElement, app: appElement, appInfo: app)
        refreshFocusedElement(app: app)
    }
    private func refreshFocusedElement(app: NSRunningApplication) {
        guard !excludedBundleIDs.contains(app.bundleIdentifier ?? "") else {
            focused = nil
            lastGoodText = nil
            return
        }
        guard let focusedApp else { return }
        var value: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(focusedApp, kAXFocusedUIElementAttribute as CFString, &value)
        var element: AXUIElement? = value == nil ? nil : (value! as! AXUIElement)
        if element == nil {
            let system = AXUIElementCreateSystemWide()
            var hit: AXUIElement?
            let point = NSEvent.mouseLocation
            let result = AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &hit)
            if result == .success {
                element = hit
                DiagnosticLog.write("focused fallback elementAtPosition bundle=\(app.bundleIdentifier ?? "unknown")")
            } else {
                DiagnosticLog.write(
                    "focused element unavailable bundle=\(app.bundleIdentifier ?? "unknown") status=\(result.rawValue)")
            }
        }
        guard let element else {
            focused = nil
            lastGoodText = nil
            return
        }
        logElementDetails(element, prefix: "focused element bundle=\(app.bundleIdentifier ?? "unknown")")
        let resolved = resolveTextElement(from: element, depth: 3)
        if let resolved {
            if let focused, !CFEqual(focused, resolved) {
                lastGoodText = nil
                lastText = nil
                lastSelectedRange = nil
            }
            focused = resolved
            logElementDetails(resolved, prefix: "resolved text element")
            observeValue(on: resolved)
        } else {
            focused = nil
            lastGoodText = nil
            DiagnosticLog.write("no supported text element found bundle=\(app.bundleIdentifier ?? "unknown")")
        }
    }
    private func resolveTextElement(from element: AXUIElement, depth: Int) -> AXUIElement? {
        if isSupportedEditable(element) { return element }
        guard depth > 0 else { return nil }
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
            let list = children as? [AXUIElement]
        else { return nil }
        for child in list { if let match = resolveTextElement(from: child, depth: depth - 1) { return match } }
        return nil
    }
    private func isSupportedEditable(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        var subrole: CFTypeRef?
        var editable: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        _ = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
        _ = AXUIElementCopyAttributeValue(element, "AXEditable" as CFString, &editable)
        let roleString = role as? String ?? ""
        let subroleString = subrole as? String ?? ""
        if subroleString == kAXSecureTextFieldSubrole as String || subroleString == "AXPasswordField" { return false }
        return (editable as? Bool == true)
            || [kAXTextFieldRole as String, kAXTextAreaRole as String, kAXComboBoxRole as String].contains(roleString)
    }
    private func observe(_ element: AXUIElement, app: AXUIElement, appInfo: NSRunningApplication) {
        let result = AXObserverCreate(appInfo.processIdentifier, callback, &elementObserver)
        guard result == .success, let observer = elementObserver else { return }
        AXObserverAddNotification(
            observer, app, kAXFocusedUIElementChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque()
        )
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
    }
    private func observeValue(on element: AXUIElement) {
        guard let observer = elementObserver else { return }
        AXObserverAddNotification(
            observer, element, kAXValueChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque())
    }
    private func removeObserver() {
        if let observer = elementObserver {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        }
        elementObserver = nil
        focused = nil
        focusedApp = nil
        lastText = nil
        lastGoodText = nil
        lastSelectedRange = nil
    }
    func snapshotNow() -> (snapshot: TextSnapshot, session: InputSessionID, screen: NSScreen?)? {
        let captured = readFocusedText(force: true)
        let live = captured?.snapshot ?? TextSnapshot(
            pid: session.pid, bundleIdentifier: nil, text: "", selectedRange: nil)
        let resolved = ShortcutSnapshotRecovery.resolve(
            live: live, lastGoodText: lastGoodText, sourceLanguage: sourceLanguage)
        guard !resolved.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return (resolved, captured?.session ?? session, captured?.screen ?? NSScreen.main)
    }
    private func readSnapshot() {
        _ = readFocusedText(force: false)
    }
    private func readFocusedText(force: Bool) -> (snapshot: TextSnapshot, session: InputSessionID, screen: NSScreen?)?
    {
        guard let app = NSWorkspace.shared.frontmostApplication,
            !excludedBundleIDs.contains(app.bundleIdentifier ?? "")
        else { return nil }
        guard let element = focused else { return nil }
        guard let live = readElementText(element) else { return nil }
        let text = live.text
        let selected = live.selected
        let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !hasContent {
            guard force else { return nil }
        } else {
            if !force, text == lastText, selected == lastSelectedRange { return nil }
            lastGoodText = text
            lastText = text
            lastSelectedRange = selected
        }
        DiagnosticLog.write("AXValue read success length=\(text.count)")
        logger.info("AXValue read success length=\(text.count, privacy: .public)")
        let screen = NSScreen.main
        let snapshot = TextSnapshot(
            pid: session.pid, bundleIdentifier: app.bundleIdentifier, text: text, selectedRange: selected)
        if !force {
            onSnapshot?(snapshot, session, screen)
        }
        return (snapshot, session, screen)
    }

    private func readElementText(_ element: AXUIElement) -> (text: String, selected: NSRange?)? {
        var selected: NSRange?
        var range: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &range)
        if let range {
            var r = CFRange()
            let ax = range as! AXValue
            if AXValueGetValue(ax, .cfRange, &r) { selected = NSRange(location: r.location, length: r.length) }
        }
        var value: CFTypeRef?
        let valueStatus = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        if valueStatus == .success, let text = value as? String,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return (text, selected)
        }
        if let ranged = stringForFullRange(element) {
            return (ranged, selected)
        }
        if valueStatus == .success, let text = value as? String {
            return (text, selected)
        }
        return nil
    }

    private func stringForFullRange(_ element: AXUIElement) -> String? {
        var countRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXNumberOfCharactersAttribute as CFString, &countRef) == .success
        else { return nil }
        let count: Int
        if let number = countRef as? NSNumber {
            count = number.intValue
        } else {
            return nil
        }
        guard count > 0 else { return nil }
        var range = CFRange(location: 0, length: count)
        guard let axRange = AXValueCreate(.cfRange, &range) else { return nil }
        var stringRef: CFTypeRef?
        let status = AXUIElementCopyParameterizedAttributeValue(
            element, kAXStringForRangeParameterizedAttribute as CFString, axRange, &stringRef)
        guard status == .success, let text = stringRef as? String,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return text
    }

    func replace(sourceWithTerminator: String, translation: String) -> Bool {
        guard let element = focused else { return false }
        var value: CFTypeRef?
        let read = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        let current = read == .success ? value as? String : nil
        return FocusedFieldReplacer.replace(
            currentText: current, sourceWithTerminator: sourceWithTerminator, translation: translation
        ) { text, caret in
            let write = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, text as CFTypeRef)
            guard write == .success else { return false }
            var range = CFRange(location: caret, length: 0)
            if let axRange = AXValueCreate(.cfRange, &range) {
                _ = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, axRange)
            }
            lastText = text
            lastGoodText = text
            lastSelectedRange = NSRange(location: caret, length: 0)
            return true
        }
    }
    private func logElementDetails(_ element: AXUIElement, prefix: String = "AX element") {
        var names: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &names)
        var role: CFTypeRef?
        var subrole: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        _ = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
        let attributes = (names as? [String] ?? []).joined(separator: ",")
        DiagnosticLog.write(
            "\(prefix) role=\(role as? String ?? "unknown") subrole=\(subrole as? String ?? "unknown") attrs=\(attributes) attrStatus=\(result.rawValue)"
        )
    }
}

private func callback(
    _ observer: AXObserver?, _ element: AXUIElement?, _ notification: CFString?, _ refcon: UnsafeMutableRawPointer?
) {
    guard let refcon else { return }
    let address = UInt(bitPattern: refcon)
    let name = notification as String? ?? ""
    MainActor.assumeIsolated {
        Unmanaged<AccessibilityMonitor>.fromOpaque(UnsafeMutableRawPointer(bitPattern: address)!).takeUnretainedValue()
            .readForCallback(name)
    }
}
extension AccessibilityMonitor {
    fileprivate func readForCallback(_ name: String) {
        if name == kAXFocusedUIElementChangedNotification as String,
            let app = NSRunningApplication(processIdentifier: session.pid)
        {
            refreshFocusedElement(app: app)
        } else {
            readSnapshot()
        }
    }
}

enum TranslationClipboard {
    static func copy(_ text: String?) -> Bool {
        copy(text, using: SystemPasteboard())
    }

    static func copy(_ text: String?, using pasteboard: PasteboardWriting) -> Bool {
        guard let text, !text.isEmpty else { return false }
        pasteboard.writeString(text)
        return true
    }
}

protocol PasteboardWriting {
    func writeString(_ text: String)
}

struct SystemPasteboard: PasteboardWriting {
    func writeString(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

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
    private let extractor = SentenceExtractor(), detector = ChineseTextDetector(), debouncer = InputDebouncer()
    private var lastSentence = "", session: InputSessionID?
    var isEnabled = true
    var excludedBundleIDs: Set<String> = []
    var delayMilliseconds: Int {
        get {
            Int(
                debouncer.delay.components.seconds * 1000 + debouncer.delay.components.attoseconds
                    / 1_000_000_000_000_000)
        }
        set { debouncer.delay = .milliseconds(newValue) }
    }
    var onSentence: ((String, String, InputSessionID, NSScreen?) -> Void)?, onEmpty: (() -> Void)?
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
        debouncer.submit(snapshot) { [weak self] snapshot in
            guard let self, self.session == session else { return }
            let sentence = self.extractor.extract(from: snapshot)
            DiagnosticLog.write(
                "debounce fired sentenceLength=\(sentence.count) hasChinese=\(self.detector.containsChinese(sentence))")
            self.logger.info(
                "debounce fired sentenceLength=\(sentence.count, privacy: .public) hasChinese=\(self.detector.containsChinese(sentence), privacy: .public)"
            )
            guard !sentence.isEmpty, self.detector.containsChinese(sentence), sentence != self.lastSentence else {
                return
            }
            self.lastSentence = sentence
            let nsText = snapshot.text as NSString
            let sentenceRange = nsText.range(of: sentence, options: .backwards)
            let sentenceKey =
                sentenceRange.location == NSNotFound
                ? "\(session.token.uuidString):\(sentence)" : nsText.substring(to: sentenceRange.location)
            self.onSentence?(sentence, sentenceKey, session, screen)
        }
    }
    func reset() {
        debouncer.cancel()
        session = nil
        lastSentence = ""
        onEmpty?()
    }
}

@MainActor final class AccessibilityMonitor {
    private let logger = Logger(subsystem: "com.liveenglish.app", category: "accessibility")
    var onSnapshot: ((TextSnapshot, InputSessionID, NSScreen?) -> Void)?
    var excludedBundleIDs: Set<String> = []
    var onFocusChanged: (() -> Void)?
    private var appObserver: NSObjectProtocol?, elementObserver: AXObserver?, pollTimer: Timer?, focused: AXUIElement?,
        lastText: String?, lastSelectedRange: NSRange?, session = InputSessionID(pid: 0)
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
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.readSnapshot() }
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
            return
        }
        logElementDetails(element, prefix: "focused element bundle=\(app.bundleIdentifier ?? "unknown")")
        let resolved = resolveTextElement(from: element, depth: 3)
        focused = resolved
        if let resolved {
            logElementDetails(resolved, prefix: "resolved text element")
            observeValue(on: resolved)
        } else {
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
        lastSelectedRange = nil
    }
    private func readSnapshot() {
        guard let element = focused else { return }
        var value: CFTypeRef?
        var range: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        guard result == .success, let text = value as? String else { return }
        _ = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &range)
        var selected: NSRange?
        if let range {
            var r = CFRange()
            let ax = range as! AXValue
            if AXValueGetValue(ax, .cfRange, &r) { selected = NSRange(location: r.location, length: r.length) }
        }
        guard text != lastText || selected != lastSelectedRange else { return }
        lastText = text
        lastSelectedRange = selected
        DiagnosticLog.write("AXValue read success length=\(text.count)")
        logger.info("AXValue read success length=\(text.count, privacy: .public)")
        let app = NSWorkspace.shared.frontmostApplication
        let screen = NSScreen.main
        onSnapshot?(
            TextSnapshot(
                pid: session.pid, bundleIdentifier: app?.bundleIdentifier, text: text, selectedRange: selected),
            session, screen)
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

import AppKit
import ApplicationServices
import OSLog
import SwiftUI
@preconcurrency import Translation

@main struct LiveEnglishApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        MenuBarExtra("FloatTrans", image: "MenuBarIcon") {
            MenuBarMenu(state: appDelegate.state)
        }.menuBarExtraStyle(.menu)
        Settings { SettingsView(state: appDelegate.state) }
        Window("Welcome to FloatTrans", id: "welcome") { WelcomeView(state: appDelegate.state) }.defaultSize(
            width: 520, height: 360)
    }
}

struct MenuBarMenu: View {
    @ObservedObject var state: AppState
    @ObservedObject private var settings: SettingsStore

    init(state: AppState) {
        self.state = state
        self._settings = ObservedObject(wrappedValue: state.settings)
    }

    var body: some View {
        let lang = settings.uiLanguage
        Button(state.enabled ? L10n.pause(lang) : L10n.resume(lang)) { state.toggle() }
        Divider()
        Button(L10n.menuSettings(lang)) { state.presentSettings() }
        Button(L10n.quit(lang)) { NSApp.terminate(nil) }
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let state: AppState
    override init() {
        state = AppState()
        super.init()
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        state.startTranslationHost()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        state.handleReopen()
        return true
    }

    // Chrome windows keep Dock / Cmd+Tab presence after the user switches apps.
    // Do not set `.accessory` from resign-active; overlay and the translation host never count.
}

@MainActor final class AppState: ObservableObject {
    private let logger = Logger(subsystem: "com.liveenglish.app", category: "runtime")
    @Published var enabled: Bool
    @Published var translation = ""
    @Published var permissionGranted: Bool
    @Published var showWelcome: Bool
    var settings: SettingsStore
    let permission = AccessibilityPermissionManager()
    let monitor = AccessibilityMonitor()
    let input = InputCoordinator()
    let llmRouter: LLMModelRouter
    let translationService: TranslationService
    let coordinator: TranslationCoordinator
    let translationHolder: TranslationSessionHolder
    let history: TranslationHistoryController
    let overlay = OverlayCoordinator()
    let speech: SpeechPerforming
    private let speechPolicy = SpeechPolicyEvaluator()
    private let hotKey = GlobalHotKey.shared
    private var currentSession: InputSessionID?
    private var currentInputRevision = 0
    private var pendingAction: PendingTranslationAction?
    private var welcomeWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private let chromeObserver = ChromeWindowObserver()
    private var permissionPoll: Task<Void, Never>?
    private var translationSettingsTask: Task<Void, Never>?
    private var translationSettingsGeneration = 0
    private var translationHostWindow: TranslationHostWindowController?
    init() {
        let store = SettingsStore()
        let enabledValue = store.enabled
        let trustedValue = AXIsProcessTrusted()
        let welcomeValue = !UserDefaults.standard.bool(forKey: "onboardingComplete")
        let holder = TranslationSessionHolder()
        let router = LLMModelRouter(models: store.llmModels, timeoutSeconds: store.llmFallbackTimeout)
        let service = TranslationService(
            localEngine: HostedTranslationEngine(holder: holder),
            llmRouter: router,
            backend: store.translationBackend,
            models: store.llmModels,
            timeoutSeconds: store.llmFallbackTimeout)
        let historyController = TranslationHistoryController()
        settings = store
        enabled = enabledValue
        permissionGranted = trustedValue
        showWelcome = welcomeValue
        translationHolder = holder
        llmRouter = router
        translationService = service
        coordinator = TranslationCoordinator(
            engine: service, sourceLanguage: store.sourceLanguage, targetLanguage: store.targetLanguage)
        history = historyController
        speech = SpeechService()
        NSLog("LiveEnglish startup trusted=%@ enabled=%@", String(trustedValue), String(enabledValue))
        DiagnosticLog.write("startup trusted=\(trustedValue) enabled=\(enabledValue)")
        logger.info("startup trusted=\(trustedValue, privacy: .public) enabled=\(enabledValue, privacy: .public)")
        input.isEnabled = enabled
        input.delayMilliseconds = Int(settings.pauseCommitDelay * 1000)
        input.sourceLanguage = settings.sourceLanguage
        input.timing = settings.translationTiming
        overlay.hideAfter = settings.hideAfter
        overlay.neverHide = settings.neverHide
        overlay.textSize = settings.textSize
        overlay.position = settings.overlayPosition
        overlay.edgeDistance = settings.overlayEdgeDistance
        overlay.behavior = settings.overlayBehavior
        monitor.onSnapshot = { [weak self] snapshot, session, screen in
            self?.input.handle(snapshot, session: session, screen: screen)
        }
        monitor.onFocusChanged = { [weak self] in self?.input.reset() }
        input.excludedBundleIDs = settings.excludedBundleIDs
        monitor.excludedBundleIDs = settings.excludedBundleIDs
        monitor.sourceLanguage = settings.sourceLanguage
        settings.onTranslationSettingsChanged = { [weak self] in self?.applyTranslationSettings() }
        settings.onHistoryRetentionChanged = { [weak self] in
            guard let self else { return }
            self.history.reload(retention: self.settings.historyRetention)
        }
        input.onInputChanged = { [weak self] session, revision in
            self?.invalidateTranslationForInputChange(session: session, revision: revision)
        }
        input.onSentence = { [weak self] text, sentenceKey, session, screen, snapshot, event, revision in
            self?.translate(
                text, sentenceKey: sentenceKey, session: session, screen: screen, snapshot: snapshot, event: event,
                revision: revision)
        }
        input.onEmpty = { [weak self] in
            self?.currentSession = nil
            self?.currentInputRevision += 1
            self?.clearPendingAction()
            self?.overlay.hide()
            self?.speech.stop()
            Task { await self?.coordinator.cancel() }
        }
        if permissionGranted && enabled {
            monitor.start()
            DiagnosticLog.write("accessibility monitor started")
            logger.info("accessibility monitor started")
        } else {
            DiagnosticLog.write("accessibility monitor skipped")
            logger.info("accessibility monitor skipped")
        }
        permissionPoll = Task { @MainActor [weak self] in
            while let self, !self.permissionGranted {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if AXIsProcessTrusted() {
                    self.permissionGranted = true
                    self.monitor.start()
                    return
                }
            }
        }
        hotKey.onAction = { [weak self] action in
            switch action {
            case .replace: self?.handleReplaceHotKey()
            case .copy: self?.handleCopyHotKey()
            case .translate: self?.handleTranslateHotKey()
            }
        }
        refreshHotKeys()
        applyTranslationSettings()
        history.reload(retention: settings.historyRetention)
        chromeObserver.onClose = { [weak self] window in self?.syncChromePresence(excluding: window) }
        chromeObserver.onMiniaturizeChange = { [weak self] in self?.syncChromePresence() }
        if showWelcome {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                self?.presentWelcome()
            }
        }
    }
    func startTranslationHost() {
        guard translationHostWindow == nil else { return }
        translationHostWindow = TranslationHostWindowController(holder: translationHolder, settings: settings)
    }

    /// Applies a settings edit to the running pipeline. Direction, engine,
    /// prompt/model order, and timeout all take effect on the next request;
    /// existing work is invalidated so stale output cannot overwrite it.
    ///
    /// TranslationSessionHolder and InputCoordinator deliberately make
    /// same-direction updates no-ops. Switching between local and LLM
    /// translation must not tear down the local TranslationSession or reset
    /// keyboard input state.
    func applyTranslationSettings() {
        let source = settings.sourceLanguage
        let target = settings.targetLanguage
        let backend = settings.translationBackend
        let timeout = settings.llmFallbackTimeout
        let models = settings.llmModels
        input.setSourceLanguage(source)
        monitor.sourceLanguage = source
        translationHolder.configure(source: source, target: target)
        currentSession = nil
        clearPendingAction()
        overlay.hide()
        speech.stop()
        translationSettingsGeneration += 1
        let generation = translationSettingsGeneration
        translationSettingsTask?.cancel()
        let coordinator = coordinator
        let service = translationService
        translationSettingsTask = Task { [weak self] in
            await coordinator.cancel()
            await coordinator.setDirection(from: source, to: target)
            await service.configure(backend: backend, models: models, timeoutSeconds: timeout)
            await coordinator.clearCache()
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.translationSettingsGeneration == generation else { return }
            }
        }
    }
    func toggle() {
        enabled.toggle()
        settings.enabled = enabled
        input.isEnabled = enabled
        if enabled {
            permissionGranted = AXIsProcessTrusted()
            monitor.start()
            refreshHotKeys()
        } else {
            input.reset()
            monitor.stop()
            clearPendingAction()
            refreshHotKeys()
            Task { await coordinator.cancel() }
            speech.stop()
            overlay.hide()
        }
    }
    func requestPermission() {
        permission.request()
        permissionGranted = AXIsProcessTrusted()
        if permissionGranted { monitor.start() }
    }
    func showOverlayTest() { overlay.show("This is a position preview.", on: NSScreen.main) }
    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        showWelcome = false
        welcomeWindow?.close()
        welcomeWindow = nil
        syncChromePresence()
    }
    func presentSettings() {
        if let settingsWindow {
            updateSettingsWindowTitle()
            AppPresence.reveal(settingsWindow)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = L10n.settingsWindowTitle(settings.uiLanguage)
        let hosting = NSHostingView(rootView: SettingsView(state: self))
        hosting.sizingOptions = .minSize
        window.contentView = hosting
        window.contentMinSize = NSSize(width: 760, height: 520)
        window.setContentSize(NSSize(width: 840, height: 700))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = chromeObserver
        settingsWindow = window
        AppPresence.reveal(window)
    }
    func handleReopen() {
        guard let window = AppPresence.windowToReopen(settings: settingsWindow, welcome: welcomeWindow) else { return }
        if window === settingsWindow { updateSettingsWindowTitle() }
        AppPresence.reveal(window)
    }
    private func syncChromePresence(excluding closing: NSWindow? = nil) {
        AppPresence.apply(
            AppPresence.activationPolicy(settings: settingsWindow, welcome: welcomeWindow, closing: closing))
    }
    func updateSettingsWindowTitle() {
        settingsWindow?.title = L10n.settingsWindowTitle(settings.uiLanguage)
    }
    private func presentWelcome() {
        guard welcomeWindow == nil else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360), styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = "Welcome to FloatTrans"
        window.contentView = NSHostingView(rootView: WelcomeView(state: self))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = chromeObserver
        welcomeWindow = window
        AppPresence.reveal(window)
    }
    private func translate(
        _ text: String,
        sentenceKey: String,
        session: InputSessionID,
        screen: NSScreen?,
        snapshot: TextSnapshot,
        event: TranslationEvent,
        revision: Int
    ) {
        let sourceLanguage = settings.sourceLanguage
        let targetLanguage = settings.targetLanguage
        currentSession = session
        currentInputRevision = revision
        let previous = pendingAction
        let sameSentence = previous?.sentenceKey == sentenceKey && previous?.session == session
        var sourceWithTerminator: String?
        if settings.replaceOriginal {
            sourceWithTerminator = FieldReplacement.evaluate(fieldText: snapshot.text, source: text)?
                .sourceWithTerminator
        }
        pendingAction = PendingTranslationAction(
            text: nil,
            sourceWithTerminator: sourceWithTerminator,
            session: session,
            sentenceKey: sentenceKey,
            applyReplaceWhenReady: sameSentence && previous?.applyReplaceWhenReady == true,
            applyCopyWhenReady: sameSentence && previous?.applyCopyWhenReady == true)
        DiagnosticLog.write("translation requested length=\(text.count)")
        logger.info("translation requested length=\(text.count, privacy: .public)")
        let coordinator = coordinator
        let settingsTask = translationSettingsTask
        let generation = translationSettingsGeneration
        Task { [weak self, coordinator] in
            await settingsTask?.value
            guard !Task.isCancelled else { return }
            guard await MainActor.run(body: { self?.translationSettingsGeneration == generation }) else { return }
            guard let result = await coordinator.translate(text) else {
                await MainActor.run {
                    DiagnosticLog.write("translation returned no result")
                    self?.logger.info("translation returned no result")
                }
                return
            }
            await MainActor.run {
                self?.acceptTranslationResult(
                    result,
                    sourceText: text,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    key: sentenceKey,
                    session: session,
                    screen: screen,
                    event: event,
                    revision: revision)
            }
        }
    }
    private func acceptTranslationResult(
        _ result: String,
        sourceText: String,
        sourceLanguage: Language,
        targetLanguage: Language,
        key sentenceKey: String,
        session: InputSessionID,
        screen: NSScreen?,
        event: TranslationEvent,
        revision: Int
    ) {
        guard currentSession == session, currentInputRevision == revision, enabled else {
            DiagnosticLog.write("translation discarded stale session")
            logger.info("translation discarded stale session")
            return
        }
        translation = result
        if pendingAction?.session == session, pendingAction?.sentenceKey == sentenceKey {
            pendingAction?.text = result
        } else {
            pendingAction = PendingTranslationAction(
                text: result, sourceWithTerminator: nil, session: session, sentenceKey: sentenceKey)
        }
        history.record(
            sourceText: sourceText,
            translatedText: result,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            retention: settings.historyRetention,
            historyKey: historyKey(for: sentenceKey, session: session))
        DiagnosticLog.write("translation result accepted length=\(result.count)")
        logger.info("translation result accepted length=\(result.count, privacy: .public)")
        overlay.show(result, key: sentenceKey, on: screen)
        speakIfAllowed(result, event: event, targetLanguage: targetLanguage)
        if pendingAction?.applyReplaceWhenReady == true { applyPendingReplace() }
        if pendingAction?.applyCopyWhenReady == true { applyPendingCopy() }
    }
    private func speakIfAllowed(_ text: String, event: TranslationEvent, targetLanguage: Language) {
        guard speechPolicy.shouldSpeak(
            speechEnabled: settings.speechEnabled,
            speechTriggers: settings.speechTriggers,
            event: event)
        else {
            DiagnosticLog.write("speech skipped")
            return
        }
        DiagnosticLog.write("speech speaking length=\(text.count)")
        speech.speak(text, language: targetLanguage)
    }

    private func historyKey(for sentenceKey: String, session: InputSessionID) -> String {
        "\(session.token.uuidString):\(sentenceKey)"
    }

    /// Each physical edit invalidates results already in flight. This matters
    /// for corrections: the old translation must never overwrite or speak
    /// after the user deleted and retyped part of the same sentence.
    private func invalidateTranslationForInputChange(session: InputSessionID, revision: Int) {
        currentSession = session
        currentInputRevision = revision
        clearPendingAction()
        overlay.hide()
        speech.stop()
    }
    func setReplaceOriginal(_ enabled: Bool) {
        settings.replaceOriginal = enabled
        refreshHotKeys()
    }

    func setCopyTranslation(_ enabled: Bool) {
        settings.copyTranslation = enabled
        refreshHotKeys()
    }

    func setReplaceShortcut(_ shortcut: ReplaceShortcut) {
        settings.replaceShortcut = shortcut
        refreshHotKeys()
    }

    func setCopyShortcut(_ shortcut: ReplaceShortcut) {
        settings.copyShortcut = shortcut
        refreshHotKeys()
    }

    func setTranslationTiming(_ timing: TranslationTiming) {
        settings.translationTiming = timing
        input.timing = timing
        refreshHotKeys()
    }

    func setTranslateShortcut(_ shortcut: ReplaceShortcut) {
        settings.translateShortcut = shortcut
        refreshHotKeys()
    }

    private func refreshHotKeys() {
        hotKey.set(.replace, shortcut: enabled && settings.replaceOriginal ? settings.replaceShortcut : nil)
        hotKey.set(.copy, shortcut: enabled && settings.copyTranslation ? settings.copyShortcut : nil)
        hotKey.set(
            .translate,
            shortcut: enabled && settings.translationTiming == .shortcut ? settings.translateShortcut : nil)
    }

    private func handleTranslateHotKey() {
        guard enabled, settings.translationTiming == .shortcut else { return }
        guard let captured = monitor.snapshotNow() else { return }
        input.translateNow(captured.snapshot, session: captured.session, screen: captured.screen)
    }

    private func handleReplaceHotKey() {
        guard enabled, settings.replaceOriginal else { return }
        if pendingAction?.text != nil, pendingAction?.sourceWithTerminator != nil {
            applyPendingReplace()
        } else if pendingAction != nil {
            pendingAction?.applyReplaceWhenReady = true
        }
    }

    private func handleCopyHotKey() {
        guard enabled, settings.copyTranslation else { return }
        if pendingAction?.text != nil {
            applyPendingCopy()
        } else if pendingAction != nil {
            pendingAction?.applyCopyWhenReady = true
        }
    }

    private func applyPendingReplace() {
        guard enabled, settings.replaceOriginal else { return }
        guard var pending = pendingAction, let translation = pending.text,
            let source = pending.sourceWithTerminator
        else { return }
        if monitor.replace(sourceWithTerminator: source, translation: translation) {
            pending.sourceWithTerminator = nil
            pending.applyReplaceWhenReady = false
            pendingAction = pending
        }
    }

    private func applyPendingCopy() {
        guard enabled, settings.copyTranslation else { return }
        _ = TranslationClipboard.copy(pendingAction?.text)
        pendingAction?.applyCopyWhenReady = false
    }

    private func clearPendingAction() {
        pendingAction = nil
        translation = ""
    }

    deinit { permissionPoll?.cancel() }
}

private struct PendingTranslationAction {
    var text: String?
    var sourceWithTerminator: String?
    var session: InputSessionID
    var sentenceKey: String
    var applyReplaceWhenReady = false
    var applyCopyWhenReady = false
}

struct AboutView: View {
    var language: UILanguage = .chinese
    var checker = UpdateChecker()
    var openURL: (URL) -> Void = { NSWorkspace.shared.open($0) }

    @State private var checkStatus: UpdateCheckStatus = .idle

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)).resizable().frame(
                width: 96, height: 96)
            Text(L10n.productName(language)).font(.largeTitle.bold())
            Text(L10n.version(language)).foregroundStyle(.secondary)
            Text(L10n.aboutBody(language)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button(L10n.checkForUpdates(language)) {
                Task { await checkForUpdates() }
            }
            .disabled(checkStatus == .checking)
            if let statusText {
                Text(statusText).font(.caption).foregroundStyle(.secondary)
            }
            Link(L10n.aboutRepo(language), destination: URL(string: "https://github.com/krisir/floattrans")!)
            Link(L10n.aboutDeveloper(language), destination: URL(string: "mailto:psychicsirk@gmail.com")!)
        }
        .padding(28)
        .frame(maxWidth: 420)
    }

    private var statusText: String? {
        switch checkStatus {
        case .idle: return nil
        case .checking: return L10n.checkForUpdatesChecking(language)
        case .upToDate: return L10n.checkForUpdatesUpToDate(language)
        case .failed: return L10n.checkForUpdatesFailed(language)
        }
    }

    private func checkForUpdates() async {
        checkStatus = .checking
        let result = await checker.check()
        if let url = result.urlToOpen { openURL(url) }
        checkStatus = result.statusAfterCheck
    }
}

enum AddExcludedAppView {
    @MainActor static func openPanel(state: AppState) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.applicationBundle]
        panel.begin { response in
            guard response == .OK, let url = panel.url, let bundleID = Bundle(url: url)?.bundleIdentifier else {
                return
            }
            state.settings.excludedBundleIDs.insert(bundleID)
            state.input.excludedBundleIDs = state.settings.excludedBundleIDs
            state.monitor.excludedBundleIDs = state.settings.excludedBundleIDs
        }
    }
}

struct WelcomeView: View {
    @ObservedObject var state: AppState
    @State private var step = 0
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "character.bubble").font(.system(size: 42)).foregroundStyle(.blue)
            Text(
                step == 0
                    ? "Write in Chinese.\nSee it in English." : step == 1 ? "Accessibility Permission" : "Try it now"
            ).font(.title).multilineTextAlignment(.center)
            Text(
                step == 0
                    ? "Live English translates what you're typing without interrupting your workflow."
                    : step == 1
                        ? "Permission lets Live English read only the editable text field. Password fields are always skipped."
                        : "Type something in Chinese in any supported text field."
            ).multilineTextAlignment(.center).foregroundStyle(.secondary)
            if step == 1 && !state.permissionGranted {
                Button("Allow Permission") { state.requestPermission() }.buttonStyle(.borderedProminent)
            }
            if step == 1 {
                LanguageResourceRow(
                    language: state.settings.uiLanguage,
                    sourceLanguage: state.settings.sourceLanguage,
                    targetLanguage: state.settings.targetLanguage)
            }
            Spacer()
            Button(step == 2 ? "Done" : "Continue") { if step < 2 { step += 1 } else { state.finishOnboarding() } }
                .buttonStyle(.borderedProminent)
        }.padding(36)
    }
}

struct TranslationHostView: View {
    let holder: TranslationSessionHolder
    @ObservedObject var settings: SettingsStore
    @State private var configuration: TranslationSession.Configuration

    init(holder: TranslationSessionHolder, settings: SettingsStore) {
        self.holder = holder
        self.settings = settings
        _configuration = State(
            initialValue: TranslationSession.Configuration(
                source: settings.sourceLanguage.locale, target: settings.targetLanguage.locale))
    }

    var body: some View {
        let source = settings.sourceLanguage
        let target = settings.targetLanguage
        Color.clear
            .frame(width: 1, height: 1)
            .onChange(of: settings.sourceLanguage) { _, _ in resetConfiguration() }
            .onChange(of: settings.targetLanguage) { _, _ in resetConfiguration() }
            .translationTask(configuration) { session in
                holder.attach(session, source: source, target: target)
            }
    }

    private func resetConfiguration() {
        holder.configure(source: settings.sourceLanguage, target: settings.targetLanguage)
        configuration = TranslationSession.Configuration(
            source: settings.sourceLanguage.locale, target: settings.targetLanguage.locale)
    }
}

@MainActor final class TranslationHostWindowController {
    private let window: NSWindow

    init(holder: TranslationSessionHolder, settings: SettingsStore) {
        let panel = NSPanel(
            contentRect: NSRect(x: -2000, y: -2000, width: 8, height: 8),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isExcludedFromWindowsMenu = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hasShadow = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.alphaValue = 0.01
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(rootView: TranslationHostView(holder: holder, settings: settings))
        panel.orderFrontRegardless()
        window = panel
    }
}

@MainActor final class AccessibilityPermissionManager {
    var isGranted: Bool { AXIsProcessTrusted() }
    func request() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

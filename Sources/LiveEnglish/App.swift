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
    let overlay = OverlayCoordinator()
    private var currentSession: InputSessionID?
    private var welcomeWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var permissionPoll: Task<Void, Never>?
    init() {
        let store = SettingsStore()
        let enabledValue = store.enabled
        let trustedValue = AXIsProcessTrusted()
        let welcomeValue = !UserDefaults.standard.bool(forKey: "onboardingComplete")
        let localEngine = Self.makeEngine()
        let llmRouterValue = LLMModelRouter(
            models: store.llmModels.map { model in
                var model = model
                model.timeoutSeconds = store.llmFallbackTimeout
                return model
            }, timeoutSeconds: store.llmFallbackTimeout)
        let translationServiceValue = TranslationService(
            localEngine: localEngine,
            llmRouter: llmRouterValue,
            backend: store.translationBackend,
            models: store.llmModels,
            timeoutSeconds: store.llmFallbackTimeout)
        settings = store
        enabled = enabledValue
        permissionGranted = trustedValue
        showWelcome = welcomeValue
        llmRouter = llmRouterValue
        translationService = translationServiceValue
        coordinator = TranslationCoordinator(
            engine: translationServiceValue,
            sourceLanguage: store.sourceLanguage,
            targetLanguage: store.targetLanguage)
        NSLog("LiveEnglish startup trusted=%@ enabled=%@", String(trustedValue), String(enabledValue))
        DiagnosticLog.write("startup trusted=\(trustedValue) enabled=\(enabledValue)")
        logger.info("startup trusted=\(trustedValue, privacy: .public) enabled=\(enabledValue, privacy: .public)")
        input.isEnabled = enabled
        input.delayMilliseconds = settings.translationSpeed
        input.sourceLanguage = settings.sourceLanguage
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
        settings.onTranslationSettingsChanged = { [weak self] in
            self?.applyTranslationSettings()
        }
        input.onSentence = { [weak self] text, sentenceKey, session, screen in
            self?.translate(text, sentenceKey: sentenceKey, session: session, screen: screen)
        }
        input.onEmpty = { [weak self] in
            self?.overlay.hide()
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
        if showWelcome {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                self?.presentWelcome()
            }
        }
        // Ensure the freshly created router uses the exact persisted snapshot
        // before Accessibility callbacks can enqueue the first translation.
        applyTranslationSettings()
    }
    private static func makeEngine() -> any TranslationEngine {
        if #available(macOS 26.0, *) { return AppleTranslationEngine() }
        return DemoTranslationEngine()
    }

    /// Propagates direction, backend, model order, and timeout changes to the
    /// live pipeline. SettingsStore invokes this on every relevant edit, so no
    /// restart is needed. Pending requests and overlays are invalidated first
    /// to prevent output generated with an old prompt/model from appearing.
    func applyTranslationSettings() {
        let source = settings.sourceLanguage
        let target = settings.targetLanguage
        let backend = settings.translationBackend
        let timeout = settings.llmFallbackTimeout
        let models = settings.llmModels.map { model in
            var model = model
            // The UI exposes one global fail-over threshold. Supplying it on
            // every runtime entry keeps the behavior deterministic even when a
            // model was decoded from an older config with its own timeout.
            model.timeoutSeconds = timeout
            return model
        }
        input.setSourceLanguage(source)
        currentSession = nil
        overlay.hide()
        Task { [weak self] in
            guard let self else { return }
            await coordinator.cancel()
            await coordinator.setDirection(from: source, to: target)
            await translationService.configure(backend: backend, models: models, timeoutSeconds: timeout)
            await coordinator.clearCache()
        }
    }
    func toggle() {
        enabled.toggle()
        settings.enabled = enabled
        input.isEnabled = enabled
        if enabled {
            permissionGranted = AXIsProcessTrusted()
            monitor.start()
        } else {
            input.reset()
            monitor.stop()
            Task { await coordinator.cancel() }
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
    }
    func presentSettings() {
        if let settingsWindow {
            updateSettingsWindowTitle()
            settingsWindow.orderFrontRegardless()
            settingsWindow.makeKey()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = L10n.settingsWindowTitle(settings.uiLanguage)
        let hosting = NSHostingView(rootView: SettingsView(state: self))
        hosting.sizingOptions = .minSize
        window.contentView = hosting
        window.contentMinSize = NSSize(width: 520, height: 360)
        window.setContentSize(NSSize(width: 520, height: 480))
        window.center()
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        window.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
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
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        welcomeWindow = window
    }
    private func translate(_ text: String, sentenceKey: String, session: InputSessionID, screen: NSScreen?) {
        currentSession = session
        DiagnosticLog.write("translation requested length=\(text.count)")
        logger.info("translation requested length=\(text.count, privacy: .public)")
        Task { [weak self] in
            guard let self else { return }
            guard let result = await coordinator.translate(text) else {
                DiagnosticLog.write("translation returned no result")
                logger.info("translation returned no result")
                return
            }
            guard currentSession == session, enabled else {
                DiagnosticLog.write("translation discarded stale session")
                logger.info("translation discarded stale session")
                return
            }
            translation = result
            DiagnosticLog.write("translation result accepted length=\(result.count)")
            logger.info("translation result accepted length=\(result.count, privacy: .public)")
            overlay.show(result, key: sentenceKey, on: screen)
        }
    }
    deinit { permissionPoll?.cancel() }
}

struct AboutView: View {
    var language: UILanguage = .chinese

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)).resizable().frame(
                width: 96, height: 96)
            Text(L10n.productName(language)).font(.largeTitle.bold())
            Text(L10n.version(language)).foregroundStyle(.secondary)
            Text(L10n.aboutBody(language)).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Link(L10n.aboutRepo(language), destination: URL(string: "https://github.com/krisir/floattrans")!)
            Link(L10n.aboutDeveloper(language), destination: URL(string: "mailto:psychicsirk@gmail.com")!)
        }
        .padding(28)
        .frame(maxWidth: 420)
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
            if step == 1 { if #available(macOS 26.0, *) { LanguagePackSetupView() } }
            Spacer()
            Button(step == 2 ? "Done" : "Continue") { if step < 2 { step += 1 } else { state.finishOnboarding() } }
                .buttonStyle(.borderedProminent)
        }.padding(36)
    }
}

@available(macOS 26.0, *)
struct LanguagePackSetupView: View {
    @State private var configuration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "zh"), target: Locale.Language(identifier: "en"))
    @State private var requested = false
    @State private var status = "Translation languages are installed by macOS on first use."
    var body: some View {
        VStack(spacing: 8) {
            Button("Install Chinese → English Languages") {
                requested = true
                configuration.invalidate()
            }
            Text(status).font(.caption).foregroundStyle(.secondary)
        }.translationTask(configuration) { session in
            guard requested else { return }
            do {
                try await session.prepareTranslation()
                status = "Downloading languages…"
                let availability = LanguageAvailability()
                for _ in 0..<120 {
                    let state = await availability.status(
                        from: Locale.Language(identifier: "zh"), to: Locale.Language(identifier: "en"))
                    if state == .installed {
                        status = "Languages ready."
                        return
                    }
                    if state == .unsupported {
                        status = "Chinese → English is not supported on this Mac."
                        return
                    }
                    try await Task.sleep(for: .seconds(1))
                }
                status = "Download is still in progress. Check Language & Region."
            } catch { status = "Language download was not completed." }
        }
    }
}

@MainActor final class AccessibilityPermissionManager {
    var isGranted: Bool { AXIsProcessTrusted() }
    func request() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

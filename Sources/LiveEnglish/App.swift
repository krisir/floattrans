import SwiftUI
import AppKit
import ApplicationServices
import OSLog
@preconcurrency import Translation

@main struct LiveEnglishApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        MenuBarExtra("FloatTrans", systemImage: appDelegate.state.enabled ? "waveform" : "pause") {
            Button(appDelegate.state.enabled ? "Pause" : "Resume") { appDelegate.state.toggle() }
            Divider(); Text("中文 → English").font(.caption)
            Button("Settings…") { appDelegate.state.presentSettings() }
            Button("Quit") { NSApp.terminate(nil) }
        }.menuBarExtraStyle(.menu)
        Settings { SettingsView(state: appDelegate.state) }
        Window("Welcome to FloatTrans", id: "welcome") { WelcomeView(state: appDelegate.state) }.defaultSize(width: 520, height: 360)
    }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let state: AppState
    override init() { state = AppState(); super.init() }
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
    let coordinator: TranslationCoordinator
    let overlay = OverlayCoordinator()
    private var currentSession: InputSessionID?
    private var welcomeWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var permissionPoll: Task<Void, Never>?
    init() {
        let store = SettingsStore(); let enabledValue = store.enabled; let trustedValue = AXIsProcessTrusted(); let welcomeValue = !UserDefaults.standard.bool(forKey: "onboardingComplete")
        settings = store; enabled = enabledValue; permissionGranted = trustedValue; showWelcome = welcomeValue; coordinator = TranslationCoordinator(engine: Self.makeEngine())
        NSLog("LiveEnglish startup trusted=%@ enabled=%@", String(trustedValue), String(enabledValue)); DiagnosticLog.write("startup trusted=\(trustedValue) enabled=\(enabledValue)"); logger.info("startup trusted=\(trustedValue, privacy: .public) enabled=\(enabledValue, privacy: .public)")
        input.isEnabled = enabled; input.delayMilliseconds = 450; overlay.hideAfter = settings.hideAfter; overlay.neverHide = settings.neverHide; overlay.textSize = settings.textSize; overlay.position = settings.overlayPosition; overlay.edgeDistance = settings.overlayEdgeDistance; overlay.behavior = settings.overlayBehavior
        monitor.onSnapshot = { [weak self] snapshot, session, screen in self?.input.handle(snapshot, session: session, screen: screen) }
        monitor.onFocusChanged = { [weak self] in self?.input.reset() }
        input.excludedBundleIDs = settings.excludedBundleIDs
        input.onSentence = { [weak self] text, sentenceKey, session, screen in self?.translate(text, sentenceKey: sentenceKey, session: session, screen: screen) }
        input.onEmpty = { [weak self] in self?.overlay.hide(); Task { await self?.coordinator.cancel() } }
        if permissionGranted && enabled { monitor.start(); DiagnosticLog.write("accessibility monitor started"); logger.info("accessibility monitor started") } else { DiagnosticLog.write("accessibility monitor skipped"); logger.info("accessibility monitor skipped") }
        permissionPoll = Task { @MainActor [weak self] in
            while let self, !self.permissionGranted {
                try? await Task.sleep(for: .seconds(1)); guard !Task.isCancelled else { return }
                if AXIsProcessTrusted() { self.permissionGranted = true; self.monitor.start(); return }
            }
        }
        if showWelcome { Task { @MainActor [weak self] in try? await Task.sleep(for: .milliseconds(250)); self?.presentWelcome() } }
    }
    private static func makeEngine() -> any TranslationEngine { if #available(macOS 26.0, *) { return AppleTranslationEngine() }; return DemoTranslationEngine() }
    func toggle() { enabled.toggle(); settings.enabled = enabled; input.isEnabled = enabled; if enabled { permissionGranted = AXIsProcessTrusted(); monitor.start() } else { input.reset(); monitor.stop(); Task { await coordinator.cancel() }; overlay.hide() } }
    func requestPermission() { permission.request(); permissionGranted = AXIsProcessTrusted(); if permissionGranted { monitor.start() } }
    func showOverlayTest() { overlay.show("This is a position preview.", on: NSScreen.main) }
    func finishOnboarding() { UserDefaults.standard.set(true, forKey: "onboardingComplete"); showWelcome = false; welcomeWindow?.close(); welcomeWindow = nil }
    func presentSettings() { if let settingsWindow { settingsWindow.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }; let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 680), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false); window.title = "FloatTrans Settings"; window.contentView = NSHostingView(rootView: SettingsView(state: self)); window.center(); window.isReleasedWhenClosed = false; window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); settingsWindow = window }
    private func presentWelcome() { guard welcomeWindow == nil else { return }; let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 360), styleMask: [.titled, .closable], backing: .buffered, defer: false); window.title = "Welcome to FloatTrans"; window.contentView = NSHostingView(rootView: WelcomeView(state: self)); window.center(); window.isReleasedWhenClosed = false; window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); welcomeWindow = window }
        private func translate(_ text: String, sentenceKey: String, session: InputSessionID, screen: NSScreen?) { currentSession = session; DiagnosticLog.write("translation requested length=\(text.count)"); logger.info("translation requested length=\(text.count, privacy: .public)"); Task { [weak self] in guard let self else { return }; guard let result = await coordinator.translate(text) else { DiagnosticLog.write("translation returned no result"); logger.info("translation returned no result"); return }; guard currentSession == session, enabled else { DiagnosticLog.write("translation discarded stale session"); logger.info("translation discarded stale session"); return }; translation = result; DiagnosticLog.write("translation result accepted length=\(result.count)"); logger.info("translation result accepted length=\(result.count, privacy: .public)"); overlay.show(result, key: sentenceKey, on: screen) } }
    deinit { permissionPoll?.cancel() }
}

struct SettingsView: View {
    @ObservedObject var state: AppState
    @ObservedObject private var settings: SettingsStore

    init(state: AppState) {
        self.state = state
        self._settings = ObservedObject(wrappedValue: state.settings)
    }

    var body: some View { Form {
        Section("General") { Toggle("Enable Live Translation", isOn: Binding(get: { state.enabled }, set: { _ in state.toggle() })); Toggle("Launch at Login", isOn: $state.settings.launchAtLogin); HStack { Text("Accessibility"); Spacer(); Text(state.permissionGranted ? "Granted" : "Required").foregroundStyle(state.permissionGranted ? .green : .red) }; if !state.permissionGranted { Button("Open System Settings") { state.requestPermission() } } }
        Section("Translation") { LabeledContent("Translate from", value: "Chinese"); LabeledContent("Translate to", value: "English"); Picker("Translation Speed", selection: Binding(get: { state.input.delayMilliseconds }, set: { state.input.delayMilliseconds = $0 })) { Text("Fast").tag(300); Text("Balanced").tag(450); Text("Relaxed").tag(700) }; if #available(macOS 26.0, *) { LanguagePackSetupView() } }
        Section("Overlay") { Picker("Position", selection: Binding(get: { settings.overlayPosition }, set: { settings.overlayPosition = $0; state.overlay.position = $0 })) { ForEach(OverlayPosition.allCases, id: \.self) { Text($0.displayName).tag($0) } }; Picker("Behavior", selection: Binding(get: { settings.overlayBehavior }, set: { settings.overlayBehavior = $0; state.overlay.behavior = $0 })) { ForEach(OverlayBehavior.allCases, id: \.self) { Text($0.rawValue).tag($0) } }; Picker("Text Size", selection: Binding(get: { settings.textSize }, set: { settings.textSize = $0; state.overlay.textSize = $0 })) { ForEach(OverlayTextSize.allCases, id: \.self) { Text($0.rawValue).tag($0) } }; HStack { Text(settings.overlayPosition == .topRight ? "Top Distance" : "Bottom Distance"); Slider(value: Binding(get: { settings.overlayEdgeDistance }, set: { settings.overlayEdgeDistance = $0; state.overlay.edgeDistance = $0 }), in: 0...300, step: 4); Text("\(Int(settings.overlayEdgeDistance))").monospacedDigit().frame(width: 36, alignment: .trailing) }; HStack { Text("Hide After"); Slider(value: Binding(get: { settings.hideAfter }, set: { settings.hideAfter = $0; state.overlay.hideAfter = $0 }), in: 3...60, step: 1).disabled(settings.neverHide); Text(settings.neverHide ? "Never" : "\(Int(settings.hideAfter)) sec").monospacedDigit().frame(width: 60, alignment: .trailing) }; Toggle("Never hide", isOn: Binding(get: { settings.neverHide }, set: { settings.neverHide = $0; state.overlay.neverHide = $0 })); Button("Preview Overlay") { state.showOverlayTest() }.buttonStyle(.bordered) }
        Section("Privacy") { ForEach(Array(state.settings.excludedBundleIDs).sorted(), id: \.self) { bundleID in ExcludedAppRow(bundleID: bundleID) { state.settings.excludedBundleIDs.remove(bundleID); state.input.excludedBundleIDs = state.settings.excludedBundleIDs } }; Button("＋ Add Application…") { AddExcludedAppView.openPanel(state: state) } }
    }.padding(20).frame(width: 460) }
}

struct ExcludedAppRow: View { let bundleID: String; let remove: () -> Void; private var appURL: URL? { NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) }; var body: some View { HStack { if let appURL { Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path)).resizable().frame(width: 24, height: 24) }; VStack(alignment: .leading) { Text(appURL.map { FileManager.default.displayName(atPath: $0.path) } ?? bundleID); Text("Don't show translations in this app").font(.caption).foregroundStyle(.secondary) }; Spacer(); Button("Remove", action: remove).buttonStyle(.link) } } }
enum AddExcludedAppView { @MainActor static func openPanel(state: AppState) { let panel = NSOpenPanel(); panel.allowsMultipleSelection = false; panel.canChooseDirectories = false; panel.canChooseFiles = true; panel.allowedContentTypes = [.applicationBundle]; panel.begin { response in guard response == .OK, let url = panel.url, let bundleID = Bundle(url: url)?.bundleIdentifier else { return }; state.settings.excludedBundleIDs.insert(bundleID); state.input.excludedBundleIDs = state.settings.excludedBundleIDs } } }

struct WelcomeView: View { @ObservedObject var state: AppState; @State private var step = 0; var body: some View { VStack(spacing: 18) { Image(systemName: "character.bubble").font(.system(size: 42)).foregroundStyle(.blue); Text(step == 0 ? "Write in Chinese.\nSee it in English." : step == 1 ? "Accessibility Permission" : "Try it now").font(.title).multilineTextAlignment(.center); Text(step == 0 ? "Live English translates what you're typing without interrupting your workflow." : step == 1 ? "Permission lets Live English read only the editable text field. Password fields are always skipped." : "Type something in Chinese in any supported text field.").multilineTextAlignment(.center).foregroundStyle(.secondary); if step == 1 && !state.permissionGranted { Button("Allow Permission") { state.requestPermission() }.buttonStyle(.borderedProminent) }; if step == 1 { if #available(macOS 26.0, *) { LanguagePackSetupView() } }; Spacer(); Button(step == 2 ? "Done" : "Continue") { if step < 2 { step += 1 } else { state.finishOnboarding() } }.buttonStyle(.borderedProminent) }.padding(36) } }

@available(macOS 26.0, *)
struct LanguagePackSetupView: View { @State private var configuration = TranslationSession.Configuration(source: Locale.Language(identifier: "zh"), target: Locale.Language(identifier: "en")); @State private var requested = false; @State private var status = "Translation languages are installed by macOS on first use."; var body: some View { VStack(spacing: 8) { Button("Install Chinese → English Languages") { requested = true; configuration.invalidate() }; Text(status).font(.caption).foregroundStyle(.secondary) }.translationTask(configuration) { session in guard requested else { return }; do { try await session.prepareTranslation(); status = "Downloading languages…"; let availability = LanguageAvailability(); for _ in 0..<120 { let state = await availability.status(from: Locale.Language(identifier: "zh"), to: Locale.Language(identifier: "en")); if state == .installed { status = "Languages ready."; return }; if state == .unsupported { status = "Chinese → English is not supported on this Mac."; return }; try await Task.sleep(for: .seconds(1)) }; status = "Download is still in progress. Check Language & Region." } catch { status = "Language download was not completed." } } } }

@MainActor final class AccessibilityPermissionManager {
    var isGranted: Bool { AXIsProcessTrusted() }
    func request() { let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary; _ = AXIsProcessTrustedWithOptions(options) }
}

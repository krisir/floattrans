import AppKit
import SwiftUI
@preconcurrency import Translation

struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .multilineTextAlignment(.trailing)
                .frame(width: 150, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }
}

struct SettingsGroupHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }
}

struct OverlayPositionPicker: View {
    @Binding var selection: OverlayPosition
    let language: UILanguage

    var body: some View {
        HStack(spacing: 12) {
            ForEach(OverlayPosition.allCases, id: \.self) { position in
                Button {
                    selection = position
                } label: {
                    VStack(spacing: 6) {
                        OverlayPositionThumbnail(position: position, isSelected: selection == position)
                        Text(position.displayName(for: language))
                            .font(.caption)
                            .foregroundStyle(selection == position ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct OverlayPositionThumbnail: View {
    let position: OverlayPosition
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.45), lineWidth: isSelected ? 2 : 1)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.55))
                    .frame(width: geo.size.width * 0.36, height: 5)
                    .position(indicatorCenter(in: geo.size))
            }
            .padding(1)
        }
        .frame(width: 64, height: 40)
    }

    private func indicatorCenter(in size: CGSize) -> CGPoint {
        let inset: CGFloat = 8
        switch position {
        case .topRight:
            return CGPoint(x: size.width - inset - size.width * 0.18, y: inset + 2.5)
        case .bottomCenter:
            return CGPoint(x: size.width / 2, y: size.height - inset - 2.5)
        case .bottomRight:
            return CGPoint(x: size.width - inset - size.width * 0.18, y: size.height - inset - 2.5)
        }
    }
}

struct SettingsView: View {
    private enum Page: CaseIterable {
        case general, translation, overlay, privacy, about

        var systemImage: String {
            switch self {
            case .general: return "gearshape"
            case .translation: return "character.bubble"
            case .overlay: return "rectangle.on.rectangle"
            case .privacy: return "lock"
            case .about: return "info.circle"
            }
        }

        func title(_ lang: UILanguage) -> String {
            switch self {
            case .general: return L10n.tabGeneral(lang)
            case .translation: return L10n.tabTranslation(lang)
            case .overlay: return L10n.tabOverlay(lang)
            case .privacy: return L10n.tabPrivacy(lang)
            case .about: return L10n.tabAbout(lang)
            }
        }
    }

    @ObservedObject var state: AppState
    @ObservedObject private var settings: SettingsStore
    @State private var selectedPage: Page = .general

    init(state: AppState) {
        self.state = state
        self._settings = ObservedObject(wrappedValue: state.settings)
    }

    private var lang: UILanguage { settings.uiLanguage }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            pageContent
        }
        .frame(minWidth: 520, idealWidth: 520, minHeight: 360, idealHeight: 480)
        .onAppear { state.updateSettingsWindowTitle() }
        .onChange(of: settings.uiLanguage) { _ in state.updateSettingsWindowTitle() }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Page.allCases, id: \.self) { page in
                tabButton(page)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func tabButton(_ page: Page) -> some View {
        let selected = selectedPage == page
        return Button {
            selectedPage = page
        } label: {
            Label(page.title(lang), systemImage: page.systemImage)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .controlSize(.small)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder
    private var pageContent: some View {
        Group {
            switch selectedPage {
            case .general: generalPage
            case .translation: translationPage
            case .overlay: overlayPage
            case .privacy: privacyPage
            case .about: aboutPage
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var generalPage: some View {
        settingsPage(title: L10n.tabGeneral(lang)) {
            SettingsRow(label: L10n.enableLiveTranslation(lang)) {
                Toggle("", isOn: Binding(get: { state.enabled }, set: { _ in state.toggle() }))
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            SettingsRow(label: L10n.launchAtLogin(lang)) {
                Toggle("", isOn: $state.settings.launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            SettingsRow(label: L10n.interfaceLanguage(lang)) {
                Picker("", selection: $settings.uiLanguage) {
                    ForEach(UILanguage.allCases) { language in
                        Text(language.pickerLabel).tag(language)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 160)
            }
            SettingsRow(label: L10n.accessibility(lang)) {
                if state.permissionGranted {
                    Text(L10n.permissionGranted(lang))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        Text(L10n.permissionHint(lang))
                            .font(.subheadline)
                            .foregroundStyle(.yellow)
                        Button(L10n.openSystemSettings(lang)) { state.requestPermission() }
                    }
                }
            }
        }
    }

    private var translationPage: some View {
        settingsPage(title: L10n.tabTranslation(lang)) {
            SettingsRow(label: L10n.translationDirection(lang)) {
                Text(L10n.translationDirectionValue(lang))
                    .foregroundStyle(.secondary)
            }
            SettingsRow(label: L10n.translationSpeed(lang)) {
                Picker(
                    "",
                    selection: Binding(
                        get: { state.input.delayMilliseconds }, set: { state.input.delayMilliseconds = $0 })
                ) {
                    Text(L10n.speedFast(lang)).tag(300)
                    Text(L10n.speedBalanced(lang)).tag(450)
                    Text(L10n.speedRelaxed(lang)).tag(700)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 260)
            }
            if #available(macOS 26.0, *) {
                SettingsRow(label: L10n.languageResources(lang)) {
                    LanguageResourceRow(language: lang)
                }
            }
        }
    }

    private var overlayPage: some View {
        settingsPage(title: L10n.tabOverlay(lang)) {
            SettingsGroupHeader(title: L10n.groupPosition(lang))
            SettingsRow(label: L10n.displayPosition(lang)) {
                OverlayPositionPicker(
                    selection: Binding(
                        get: { settings.overlayPosition },
                        set: {
                            settings.overlayPosition = $0
                            state.overlay.position = $0
                        }
                    ),
                    language: lang
                )
            }
            SettingsGroupHeader(title: L10n.groupAppearance(lang))
            SettingsRow(label: L10n.textSize(lang)) {
                Picker(
                    "",
                    selection: Binding(
                        get: { settings.textSize },
                        set: {
                            settings.textSize = $0
                            state.overlay.textSize = $0
                        })
                ) {
                    ForEach(OverlayTextSize.allCases, id: \.self) { Text($0.displayName(for: lang)).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 160)
            }
            SettingsRow(label: L10n.edgeDistance(lang)) {
                HStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { settings.overlayEdgeDistance },
                            set: {
                                settings.overlayEdgeDistance = $0
                                state.overlay.edgeDistance = $0
                            }), in: 0...300, step: 4)
                    Text("\(Int(settings.overlayEdgeDistance))")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            }
            SettingsGroupHeader(title: L10n.groupBehavior(lang))
            SettingsRow(label: L10n.newTranslationBehavior(lang)) {
                Picker(
                    "",
                    selection: Binding(
                        get: { settings.overlayBehavior },
                        set: {
                            settings.overlayBehavior = $0
                            state.overlay.behavior = $0
                        })
                ) {
                    ForEach(OverlayBehavior.allCases, id: \.self) { Text($0.displayName(for: lang)).tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 200)
            }
            SettingsRow(label: L10n.hideAfter(lang)) {
                HStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { settings.hideAfter },
                            set: {
                                settings.hideAfter = $0
                                state.overlay.hideAfter = $0
                            }), in: 5...60, step: 1
                    )
                    .disabled(settings.neverHide)
                    Text(L10n.seconds(lang, Int(settings.hideAfter)))
                        .monospacedDigit()
                        .frame(width: 56, alignment: .trailing)
                }
            }
            SettingsRow(label: L10n.neverHide(lang)) {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settings.neverHide },
                        set: {
                            settings.neverHide = $0
                            state.overlay.neverHide = $0
                        })
                )
                .labelsHidden()
                .toggleStyle(.checkbox)
            }
            SettingsRow(label: "") {
                Button(L10n.previewOverlay(lang)) { state.showOverlayTest() }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var privacyPage: some View {
        settingsPage(title: L10n.tabPrivacy(lang)) {
            Text(L10n.privacyExplanation(lang))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(state.settings.excludedBundleIDs).sorted(), id: \.self) { bundleID in
                ExcludedAppRow(bundleID: bundleID, language: lang) {
                    state.settings.excludedBundleIDs.remove(bundleID)
                    state.input.excludedBundleIDs = state.settings.excludedBundleIDs
                    state.monitor.excludedBundleIDs = state.settings.excludedBundleIDs
                }
            }
            SettingsRow(label: "") {
                Button(L10n.addApplication(lang)) { AddExcludedAppView.openPanel(state: state) }
            }
        }
    }

    private var aboutPage: some View {
        settingsPage(title: L10n.tabAbout(lang)) {
            AboutView(language: lang)
                .frame(maxWidth: .infinity)
        }
    }

    private func settingsPage<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .font(.title2.bold())
                content()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExcludedAppRow: View {
    let bundleID: String
    let language: UILanguage
    let remove: () -> Void
    private var appURL: URL? { NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) }

    var body: some View {
        HStack(spacing: 10) {
            if let appURL {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app")
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.secondary)
            }
            Text(appURL.map { FileManager.default.displayName(atPath: $0.path) } ?? L10n.unknownApp(language))
            Spacer()
            Button(action: remove) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(Color.secondary.opacity(0.18)))
            }
            .buttonStyle(.plain)
        }
    }
}

@available(macOS 26.0, *)
struct LanguageResourceRow: View {
    let language: UILanguage

    private enum PackState {
        case checking, installed, unsupported, available, downloading, failed
    }

    @State private var packState: PackState = .checking
    @State private var progressText = ""
    @State private var configuration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "zh"), target: Locale.Language(identifier: "en"))
    @State private var requested = false

    var body: some View {
        Group {
            switch packState {
            case .checking:
                Text(L10n.languagesChecking(language))
                    .foregroundStyle(.secondary)
            case .installed:
                Text(L10n.languagesReady(language))
                    .foregroundStyle(.secondary)
            case .unsupported:
                Text(L10n.languagesUnsupported(language))
                    .foregroundStyle(.secondary)
            case .available:
                Button(L10n.downloadLanguage(language)) {
                    startDownload()
                }
            case .downloading:
                Text(progressText)
                    .foregroundStyle(.secondary)
            case .failed:
                VStack(alignment: .leading, spacing: 6) {
                    Text(progressText)
                        .foregroundStyle(.secondary)
                    Button(L10n.downloadLanguage(language)) { startDownload() }
                }
            }
        }
        .task { await refreshAvailability() }
        .translationTask(configuration) { session in
            guard requested else { return }
            do {
                try await session.prepareTranslation()
                progressText = L10n.languagesDownloading(language)
                let availability = LanguageAvailability()
                for _ in 0..<120 {
                    let state = await availability.status(
                        from: Locale.Language(identifier: "zh"), to: Locale.Language(identifier: "en"))
                    if state == .installed {
                        packState = .installed
                        return
                    }
                    if state == .unsupported {
                        packState = .unsupported
                        return
                    }
                    try await Task.sleep(for: .seconds(1))
                }
                progressText = L10n.languagesStillDownloading(language)
                packState = .failed
            } catch {
                progressText = L10n.languagesDownloadFailed(language)
                packState = .failed
            }
        }
    }

    private func startDownload() {
        requested = true
        packState = .downloading
        progressText = L10n.languagesPreparing(language)
        configuration.invalidate()
    }

    private func refreshAvailability() async {
        let availability = LanguageAvailability()
        let state = await availability.status(
            from: Locale.Language(identifier: "zh"), to: Locale.Language(identifier: "en"))
        switch state {
        case .installed: packState = .installed
        case .unsupported: packState = .unsupported
        default: packState = .available
        }
    }
}

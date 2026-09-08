import AppKit
import SwiftUI
@preconcurrency import Translation

struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(label)
                .multilineTextAlignment(.trailing)
                .frame(width: 168, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }
}

/// A light material panel keeps dense settings readable while preserving the
/// native macOS appearance in both light and dark mode.
struct SettingsPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
    @State private var draggedModelID: UUID?

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
        .frame(minWidth: 680, idealWidth: 760, minHeight: 520, idealHeight: 700)
        .onAppear { state.updateSettingsWindowTitle() }
        .onChange(of: settings.uiLanguage) { _, _ in state.updateSettingsWindowTitle() }
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
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? Color.accentColor.opacity(0.12) : Color.clear)
                }
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
            SettingsRow(label: L10n.translationBackend(lang)) {
                Picker("", selection: $settings.translationBackend) {
                    ForEach(TranslationBackend.allCases) { backend in
                        Text(backend.displayName(for: lang)).tag(backend)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 220)
            }
            SettingsRow(label: L10n.sourceLanguage(lang)) {
                Picker(
                    "",
                    selection: Binding(
                        get: { settings.sourceLanguage },
                        set: { source in
                            settings.sourceLanguage = source
                            if settings.targetLanguage == source {
                                settings.targetLanguage = source == .english ? .chinese : .english
                            }
                        })
                ) {
                    ForEach(Language.allCases) { language in
                        Text(languageName(language)).tag(language)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 220)
            }
            SettingsRow(label: L10n.targetLanguage(lang)) {
                Picker("", selection: $settings.targetLanguage) {
                    ForEach(Language.allCases.filter { $0 != settings.sourceLanguage }) { language in
                        Text(languageName(language)).tag(language)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 220)
            }
            SettingsRow(label: L10n.translationDirection(lang)) {
                Text(L10n.translationDirectionValue(settings.sourceLanguage, settings.targetLanguage, lang))
                    .foregroundStyle(.secondary)
            }
            SettingsRow(label: L10n.translationSpeed(lang)) {
                Picker(
                    "",
                    selection: Binding(
                        get: { state.settings.translationSpeed },
                        set: {
                            state.settings.translationSpeed = $0
                            state.input.delayMilliseconds = $0
                        })
                ) {
                    Text(L10n.speedFast(lang)).tag(300)
                    Text(L10n.speedBalanced(lang)).tag(450)
                    Text(L10n.speedRelaxed(lang)).tag(700)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 260)
            }
            SettingsRow(label: L10n.translationTiming(lang)) {
                Picker(
                    "",
                    selection: Binding(
                        get: { settings.translationTiming },
                        set: { state.setTranslationTiming($0) })
                ) {
                    ForEach(TranslationTiming.allCases, id: \.self) { mode in
                        Text(mode.displayName(for: lang)).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 260)
            }
            if settings.translationTiming == .shortcut {
                SettingsRow(label: L10n.translateShortcut(lang)) {
                    ShortcutRecorderButton(
                        language: lang,
                        shortcut: settings.translateShortcut,
                        onCommit: { state.setTranslateShortcut($0) })
                }
            }
            if settings.translationBackend == .local {
                SettingsRow(label: L10n.languageResources(lang)) {
                    LanguageResourceRow(
                        language: lang,
                        sourceLanguage: settings.sourceLanguage,
                        targetLanguage: settings.targetLanguage)
                }
                Text(L10n.localTranslationPrivacy(lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 184)
            } else {
                modelSettingsSection
            }
            SettingsGroupHeader(title: L10n.groupActions(lang))
            SettingsRow(label: L10n.replaceOriginal(lang)) {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settings.replaceOriginal },
                        set: { state.setReplaceOriginal($0) })
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }
            SettingsRow(label: L10n.replaceShortcut(lang)) {
                ShortcutRecorderButton(
                    language: lang,
                    shortcut: settings.replaceShortcut,
                    onCommit: { state.setReplaceShortcut($0) })
            }
            Text(L10n.replaceOriginalHint(lang))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 184)
            SettingsRow(label: L10n.copyTranslation(lang)) {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settings.copyTranslation },
                        set: { state.setCopyTranslation($0) })
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }
            SettingsRow(label: L10n.copyShortcut(lang)) {
                ShortcutRecorderButton(
                    language: lang,
                    shortcut: settings.copyShortcut,
                    onCommit: { state.setCopyShortcut($0) })
            }
            Text(L10n.copyTranslationHint(lang))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 184)
            SettingsGroupHeader(title: L10n.groupSpeech(lang))
            SettingsRow(label: L10n.readTranslationsAloud(lang)) {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settings.speechEnabled },
                        set: {
                            settings.speechEnabled = $0
                            if !$0 { state.speech.stop() }
                        })
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }
            if settings.speechEnabled, settings.translationTiming == .pause {
                Text(L10n.autoSpeakTimingHint(lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 184)
            }
        }
    }

    @ViewBuilder
    private var modelSettingsSection: some View {
        SettingsGroupHeader(title: L10n.modelSettings(lang))
        Text(L10n.modelSettingsHint(lang))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.leading, 184)
        SettingsRow(label: L10n.failoverTimeout(lang)) {
            HStack(spacing: 8) {
                Slider(value: $settings.llmFallbackTimeout, in: 1...120, step: 1)
                Text(L10n.timeoutSeconds(lang, Int(settings.llmFallbackTimeout)))
                    .monospacedDigit()
                    .frame(width: 112, alignment: .trailing)
            }
            .frame(maxWidth: 290)
        }
        Text(L10n.apiKeyKeychainHint(lang))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.leading, 184)
        if settings.llmModels.isEmpty {
            Text(L10n.noModels(lang))
                .foregroundStyle(.secondary)
                .padding(.leading, 184)
        } else {
            // This is intentionally a VStack rather than a nested List: the
            // page's outer ScrollView is the only scroll container. Rows are
            // still draggable to reorder models within that single viewport.
            VStack(alignment: .leading, spacing: 8) {
                ForEach(settings.llmModels) { model in
                    LLMModelEditor(
                        model: model,
                        language: lang,
                        save: { settings.updateLLMModel($0) },
                        remove: { settings.removeLLMModel(id: model.id) })
                        .padding(10)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .onDrag {
                            draggedModelID = model.id
                            return NSItemProvider(object: model.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: ModelOrderDropDelegate(
                                targetID: model.id,
                                models: $settings.llmModels,
                                draggedID: $draggedModelID))
                }
            }
            .padding(.leading, 184)
        }
        SettingsRow(label: "") {
            Button(L10n.addModel(lang)) { settings.addLLMModel(defaultModel()) }
                .buttonStyle(.bordered)
        }
        Text(L10n.llmTranslationPrivacy(lang))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.leading, 184)
    }

    private func languageName(_ language: Language) -> String {
        lang == .chinese ? language.chineseName : language.englishName
    }

    private func defaultModel() -> LLMModelConfiguration {
        LLMModelConfiguration(
            name: lang == .chinese ? "新的 API 模型" : "New API Model",
            provider: .openAICompatible,
            baseURL: LLMProvider.openAICompatible.defaultBaseURL,
            model: LLMProvider.openAICompatible.defaultModel,
            timeoutSeconds: 0)
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

    private func settingsPage<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(title)
                        .font(.title2.bold())
                    Spacer()
                }
                SettingsPanel { content() }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.72))
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

struct ShortcutRecorderButton: View {
    let language: UILanguage
    let shortcut: ReplaceShortcut
    let onCommit: (ReplaceShortcut) -> Void
    @State private var recording = false

    var body: some View {
        Button(recording ? L10n.shortcutRecording(language) : shortcut.displayString) {
            recording = true
        }
        .background {
            ShortcutKeyMonitor(isActive: $recording) { event in
                if UInt32(event.keyCode) == ReplaceShortcut.escapeKeyCode {
                    recording = false
                    return
                }
                if let recorded = ReplaceShortcut.from(event: event) {
                    onCommit(recorded)
                    recording = false
                }
            }
        }
    }
}

private struct ShortcutKeyMonitor: NSViewRepresentable {
    @Binding var isActive: Bool
    var onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isActive = isActive
        context.coordinator.onKeyDown = onKeyDown
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.remove()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var isActive = false
        var onKeyDown: ((NSEvent) -> Void)?
        private var monitor: Any?

        func install() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isActive else { return event }
                self.onKeyDown?(event)
                return nil
            }
        }

        func remove() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }
}

private struct ModelOrderDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var models: [LLMModelConfiguration]
    @Binding var draggedID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedID, draggedID != targetID,
            let from = models.firstIndex(where: { $0.id == draggedID }),
            let to = models.firstIndex(where: { $0.id == targetID })
        else { return }
        withAnimation(.snappy) {
            models.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        return true
    }
}

/// Editable row for one provider in the user-defined fail-over order.
struct LLMModelEditor: View {
    @State private var draft: LLMModelConfiguration
    @State private var isExpanded = false
    let language: UILanguage
    let save: (LLMModelConfiguration) -> Void
    let remove: () -> Void

    init(
        model: LLMModelConfiguration,
        language: UILanguage,
        save: @escaping (LLMModelConfiguration) -> Void,
        remove: @escaping () -> Void
    ) {
        var initialDraft = model
        // Older saved configurations used an empty string to mean the
        // built-in prompt. Show the actual default in the editor so it can be
        // reviewed and modified without asking the user to reconstruct it.
        if initialDraft.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            initialDraft.systemPrompt = LLMTranslationPrompt.defaultSystemPrompt
        }
        _draft = State(initialValue: initialDraft)
        self.language = language
        self.save = save
        self.remove = remove
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.tertiary)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(draft.name.isEmpty ? L10n.modelPlaceholder(language) : draft.name)
                            .font(.subheadline.weight(.semibold))
                        if !draft.model.isEmpty {
                            Text(draft.model)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(draft.enabled ? Color.green : Color.secondary.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(draft.name.isEmpty ? L10n.modelPlaceholder(language) : draft.name)

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                SettingsRow(label: L10n.modelName(language)) {
                    TextField(L10n.modelPlaceholder(language), text: $draft.name).textFieldStyle(.roundedBorder)
                }
                SettingsRow(label: L10n.provider(language)) {
                    Picker("", selection: $draft.provider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(L10n.providerName(provider, language)).tag(provider)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: draft.provider) { _, provider in
                        if draft.baseURL.isEmpty || draft.baseURL == LLMProvider.openAICompatible.defaultBaseURL {
                            draft.baseURL = provider.defaultBaseURL
                        }
                        if draft.model.isEmpty { draft.model = provider.defaultModel }
                    }
                }
                SettingsRow(label: L10n.endpointURL(language)) {
                    TextField(L10n.urlPlaceholder(language), text: $draft.baseURL).textFieldStyle(.roundedBorder)
                }
                SettingsRow(label: L10n.apiKey(language)) {
                    SecureField("", text: $draft.apiKey).textFieldStyle(.roundedBorder)
                }
                SettingsRow(label: L10n.modelID(language)) {
                    TextField(L10n.modelIDPlaceholder(language), text: $draft.model).textFieldStyle(.roundedBorder)
                }
                SettingsRow(label: L10n.thinkingMode(language)) {
                    Picker("", selection: $draft.thinking) {
                        ForEach(LLMThinkingMode.allCases) { mode in
                            Text(thinkingName(mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                SettingsRow(label: L10n.prompt(language)) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $draft.systemPrompt)
                            .frame(minHeight: 110)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.secondary.opacity(0.25)))
                        HStack {
                            Text(L10n.promptHint(language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(L10n.restoreDefaultPrompt(language)) {
                                draft.systemPrompt = LLMTranslationPrompt.defaultSystemPrompt
                            }
                            .controlSize(.small)
                        }
                    }
                }
                HStack {
                    Toggle(L10n.modelEnabled(language), isOn: $draft.enabled).toggleStyle(.checkbox)
                    Spacer()
                    Button(L10n.removeModel(language), role: .destructive, action: remove)
                }
                }
                .padding(.top, 2)
            }
        }
        .onChange(of: draft) { _, updated in save(updated) }
    }

    private func thinkingName(_ mode: LLMThinkingMode) -> String {
        switch mode {
        case .automatic: return L10n.thinkingAutomatic(language)
        case .nonThinking: return L10n.thinkingOff(language)
        case .thinking: return L10n.thinkingOn(language)
        }
    }
}

struct LanguageResourceRow: View {
    let language: UILanguage
    let sourceLanguage: Language
    let targetLanguage: Language

    private enum PackState {
        case checking, installed, unsupported, available, downloading, failed
    }

    @State private var packState: PackState = .checking
    @State private var progressText = ""
    @State private var configuration: TranslationSession.Configuration
    @State private var requested = false

    init(language: UILanguage, sourceLanguage: Language, targetLanguage: Language) {
        self.language = language
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        _configuration = State(
            initialValue: TranslationSession.Configuration(source: sourceLanguage.locale, target: targetLanguage.locale))
    }

    var body: some View {
        Group {
            switch packState {
            case .checking:
                Text(L10n.languagesChecking(language))
                    .foregroundStyle(.secondary)
            case .installed:
                Text(L10n.languagesReady(sourceLanguage, targetLanguage, language))
                    .foregroundStyle(.secondary)
            case .unsupported:
                Text(L10n.languagesUnsupported(sourceLanguage, targetLanguage, language))
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
        .task(id: "\(sourceLanguage.rawValue)-\(targetLanguage.rawValue)") {
            requested = false
            configuration = TranslationSession.Configuration(source: sourceLanguage.locale, target: targetLanguage.locale)
            await refreshAvailability()
        }
        .translationTask(configuration) { session in
            guard requested else { return }
            do {
                try await session.prepareTranslation()
                progressText = L10n.languagesDownloading(language)
                let availability = LanguageAvailability()
                for _ in 0..<120 {
                    let state = await availability.status(from: sourceLanguage.locale, to: targetLanguage.locale)
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
                progressText = L10n.languagesStillDownloading(sourceLanguage, targetLanguage, language)
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
        let state = await LanguageAvailability().status(from: sourceLanguage.locale, to: targetLanguage.locale)
        switch state {
        case .installed: packState = .installed
        case .unsupported: packState = .unsupported
        default: packState = .available
        }
    }
}

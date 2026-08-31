import Foundation
import ServiceManagement

enum OverlayTextSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    var points: CGFloat {
        switch self {
        case .small: return 15
        case .medium: return 18
        case .large: return 22
        }
    }
    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .small: return L10n.sizeSmall(lang)
        case .medium: return L10n.sizeMedium(lang)
        case .large: return L10n.sizeLarge(lang)
        }
    }
}

enum OverlayPosition: String, CaseIterable {
    case topRight = "Top Right"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"

    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .topRight: return L10n.positionTopRight(lang)
        case .bottomCenter: return L10n.positionBottomCenter(lang)
        case .bottomRight: return L10n.positionBottomRight(lang)
        }
    }
    var symbolName: String {
        switch self {
        case .topRight: return "rectangle.topright.inset.filled"
        case .bottomCenter: return "rectangle.bottomhalf.inset.filled"
        case .bottomRight: return "rectangle.bottomright.inset.filled"
        }
    }
}

enum OverlayBehavior: String, CaseIterable {
    case replace = "Replace Previous"
    case stack = "Stack Below"
    func displayName(for lang: UILanguage) -> String {
        switch self {
        case .replace: return L10n.behaviorReplace(lang)
        case .stack: return L10n.behaviorStack(lang)
        }
    }
}

@MainActor final class SettingsStore: ObservableObject {
    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: "enabled") } }
    @Published var hideAfter: Double {
        didSet {
            let clamped = min(max(hideAfter, 5), 60)
            if hideAfter != clamped {
                hideAfter = clamped
                return
            }
            defaults.set(hideAfter, forKey: "hideAfter")
        }
    }
    @Published var neverHide: Bool { didSet { defaults.set(neverHide, forKey: "neverHide") } }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem(launchAtLogin)
        }
    }
    @Published var textSize: OverlayTextSize { didSet { defaults.set(textSize.rawValue, forKey: "textSize") } }
    @Published var overlayPosition: OverlayPosition {
        didSet { defaults.set(overlayPosition.rawValue, forKey: "overlayPosition") }
    }
    @Published var overlayEdgeDistance: Double {
        didSet { defaults.set(overlayEdgeDistance, forKey: "overlayEdgeDistance") }
    }
    @Published var overlayBehavior: OverlayBehavior {
        didSet { defaults.set(overlayBehavior.rawValue, forKey: "overlayBehavior") }
    }
    @Published var uiLanguage: UILanguage { didSet { defaults.set(uiLanguage.rawValue, forKey: "uiLanguage") } }
    @Published var excludedBundleIDs: Set<String> {
        didSet { defaults.set(Array(excludedBundleIDs), forKey: "excludedBundleIDs") }
    }
    private let defaults = UserDefaults.standard

    init() {
        enabled = defaults.object(forKey: "enabled") as? Bool ?? true
        let storedHideAfter = defaults.object(forKey: "hideAfter") as? Double
        let hideAfterValue = min(max(storedHideAfter ?? 5, 5), 60)
        hideAfter = hideAfterValue
        if storedHideAfter != hideAfterValue { defaults.set(hideAfterValue, forKey: "hideAfter") }
        neverHide = defaults.object(forKey: "neverHide") as? Bool ?? false
        launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        textSize = OverlayTextSize(rawValue: defaults.string(forKey: "textSize") ?? "Medium") ?? .medium
        overlayPosition =
            OverlayPosition(rawValue: defaults.string(forKey: "overlayPosition") ?? "Bottom Center") ?? .bottomCenter
        overlayEdgeDistance = min(max(defaults.object(forKey: "overlayEdgeDistance") as? Double ?? 48, 0), 300)
        let storedBehavior = defaults.string(forKey: "overlayBehavior")
        if storedBehavior == "Keep Previous" {
            overlayBehavior = .stack
            defaults.set(OverlayBehavior.stack.rawValue, forKey: "overlayBehavior")
        } else {
            overlayBehavior = OverlayBehavior(rawValue: storedBehavior ?? OverlayBehavior.replace.rawValue) ?? .replace
        }
        uiLanguage =
            UILanguage(rawValue: defaults.string(forKey: "uiLanguage") ?? UILanguage.chinese.rawValue) ?? .chinese
        excludedBundleIDs = Set(
            defaults.stringArray(forKey: "excludedBundleIDs") ?? [
                "com.agilebits.onepassword7", "com.apple.keychainaccess", "com.apple.dt.Xcode", "com.openai.codex",
                "cc.kristar.floattrans",
            ])
    }

    private func updateLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // unavailable for an unbundled debug executable
        }
    }
}

import Foundation
import ServiceManagement

enum OverlayTextSize: String, CaseIterable { case small = "Small", medium = "Medium", large = "Large"
    var points: CGFloat { switch self { case .small: return 15; case .medium: return 18; case .large: return 22 } }
}

enum OverlayPosition: String, CaseIterable {
    case topRight = "Top Right"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"

    var displayName: String { rawValue }
    var symbolName: String { switch self { case .topRight: return "rectangle.topright.inset.filled"; case .bottomCenter: return "rectangle.bottomhalf.inset.filled"; case .bottomRight: return "rectangle.bottomright.inset.filled" } }
}
enum OverlayBehavior: String, CaseIterable { case replace = "Replace Previous", stack = "Keep Previous" }

@MainActor final class SettingsStore: ObservableObject {
    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: "enabled") } }
    @Published var hideAfter: Double { didSet { defaults.set(hideAfter, forKey: "hideAfter") } }
    @Published var neverHide: Bool { didSet { defaults.set(neverHide, forKey: "neverHide") } }
    @Published var launchAtLogin: Bool { didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin"); updateLoginItem(launchAtLogin) } }
    @Published var textSize: OverlayTextSize { didSet { defaults.set(textSize.rawValue, forKey: "textSize") } }
    @Published var overlayPosition: OverlayPosition { didSet { defaults.set(overlayPosition.rawValue, forKey: "overlayPosition") } }
    @Published var overlayEdgeDistance: Double { didSet { defaults.set(overlayEdgeDistance, forKey: "overlayEdgeDistance") } }
    @Published var overlayBehavior: OverlayBehavior { didSet { defaults.set(overlayBehavior.rawValue, forKey: "overlayBehavior") } }
    @Published var excludedBundleIDs: Set<String> { didSet { defaults.set(Array(excludedBundleIDs), forKey: "excludedBundleIDs") } }
    private let defaults = UserDefaults.standard
    init() { enabled = defaults.object(forKey: "enabled") as? Bool ?? true; hideAfter = min(max(defaults.object(forKey: "hideAfter") as? Double ?? 4, 3), 60); neverHide = defaults.object(forKey: "neverHide") as? Bool ?? false; launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? false; textSize = OverlayTextSize(rawValue: defaults.string(forKey: "textSize") ?? "Medium") ?? .medium; overlayPosition = OverlayPosition(rawValue: defaults.string(forKey: "overlayPosition") ?? "Bottom Center") ?? .bottomCenter; overlayEdgeDistance = min(max(defaults.object(forKey: "overlayEdgeDistance") as? Double ?? 48, 0), 300); overlayBehavior = OverlayBehavior(rawValue: defaults.string(forKey: "overlayBehavior") ?? OverlayBehavior.stack.rawValue) ?? .stack; excludedBundleIDs = Set(defaults.stringArray(forKey: "excludedBundleIDs") ?? ["com.agilebits.onepassword7", "com.apple.keychainaccess"]) }
    private func updateLoginItem(_ enabled: Bool) { do { if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } } catch { /* unavailable for an unbundled debug executable */ } }
}

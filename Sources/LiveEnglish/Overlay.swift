import AppKit
import SwiftUI

struct TranslationOverlayView: View {
    let text: String
    let fontSize: CGFloat
    let onClose: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(text).font(.system(size: fontSize, weight: .medium)).foregroundStyle(.primary).multilineTextAlignment(
                .center
            ).lineLimit(nil).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity).padding(
                .leading, 24
            ).padding(.vertical, 14)
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(.secondary)
            }.buttonStyle(.plain).padding(.top, 8).padding(.trailing, 8)
        }.frame(minWidth: 360, maxWidth: 720).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

@MainActor final class OverlayCoordinator {
    private final class Entry {
        let id: UUID
        let key: String
        let panel: NSPanel
        var hideTask: Task<Void, Never>?
        init(id: UUID, key: String, panel: NSPanel) {
            self.id = id
            self.key = key
            self.panel = panel
        }
    }
    private var entries: [Entry] = []
    var hideAfter: Double = 4
    var neverHide = false
    var textSize: OverlayTextSize = .medium
    var position: OverlayPosition = .bottomCenter
    var edgeDistance: Double = 48
    var behavior: OverlayBehavior = .stack
    func show(_ text: String, on screen: NSScreen?) { show(text, key: UUID().uuidString, on: screen) }
    func show(_ text: String, key: String, on screen: NSScreen?) {
        guard !text.isEmpty else {
            hide()
            return
        }
        if let existing = entries.first(where: { $0.key == key }) {
            existing.panel.contentView = NSHostingView(
                rootView: TranslationOverlayView(text: text, fontSize: textSize.points) { [weak self] in
                    self?.remove(existing.id)
                })
            relayout(on: screen)
            armHideTimer(existing)
            return
        }
        if behavior == .replace { hide() }
        if entries.count >= 3 { remove(entries[0].id) }
        let target = screen ?? NSScreen.main
        let id = UUID()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 64), styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hostingView = NSHostingView(
            rootView: TranslationOverlayView(text: text, fontSize: textSize.points) { [weak self] in self?.remove(id) })
        panel.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        let entry = Entry(id: id, key: key, panel: panel)
        entries.append(entry)
        relayout(on: target)
        panel.orderFrontRegardless()
        armHideTimer(entry)
    }
    var visibleCount: Int { entries.count }
    private func armHideTimer(_ entry: Entry) {
        entry.hideTask?.cancel()
        entry.hideTask = nil
        guard !neverHide else { return }
        let seconds = hideAfter
        let id = entry.id
        entry.hideTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self.remove(id)
        }
    }
    func hide() {
        for entry in entries {
            entry.hideTask?.cancel()
            entry.panel.orderOut(nil)
        }
        entries.removeAll()
    }
    private func remove(_ id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = entries.remove(at: index)
        entry.hideTask?.cancel()
        entry.panel.orderOut(nil)
        relayout(on: NSScreen.main)
    }
    private func relayout(on screen: NSScreen?) {
        for (index, entry) in entries.enumerated() {
            entry.panel.contentView?.layoutSubtreeIfNeeded()
            let size = entry.panel.contentView?.fittingSize ?? entry.panel.frame.size
            entry.panel.setFrame(position(for: size, on: screen, stackIndex: index), display: true)
        }
    }
    private func position(for size: NSSize, on screen: NSScreen?, stackIndex: Int) -> NSRect {
        let frame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let distance = CGFloat(max(0, edgeDistance))
        let offset = CGFloat(stackIndex) * (size.height + 10)
        switch position {
        case .topRight:
            return NSRect(
                x: frame.maxX - size.width - distance, y: frame.maxY - size.height - distance - offset,
                width: size.width, height: size.height)
        case .bottomRight:
            return NSRect(
                x: frame.maxX - size.width - distance, y: frame.minY + distance + offset, width: size.width,
                height: size.height)
        case .bottomCenter:
            return NSRect(
                x: frame.midX - size.width / 2, y: frame.minY + distance + offset, width: size.width,
                height: size.height)
        }
    }
}

enum OverlayScreenGeometry {
    static func cocoaRect(axPosition: CGPoint, axSize: CGSize, desktopMaxY: CGFloat) -> CGRect {
        CGRect(
            x: axPosition.x, y: desktopMaxY - axPosition.y - axSize.height, width: axSize.width, height: axSize.height)
    }

    static func screenIndex(windowFrame: CGRect?, mouseLocation: CGPoint, screens: [CGRect]) -> Int? {
        if let windowFrame {
            var bestIndex: Int?
            var bestArea: CGFloat = 0
            for (index, frame) in screens.enumerated() {
                let intersection = frame.intersection(windowFrame)
                guard !intersection.isNull, !intersection.isInfinite else { continue }
                let area = intersection.width * intersection.height
                if area > bestArea {
                    bestArea = area
                    bestIndex = index
                }
            }
            if let bestIndex, bestArea > 0 { return bestIndex }
        }
        if let index = screens.firstIndex(where: { $0.contains(mouseLocation) }) {
            return index
        }
        return nil
    }
}

enum OverlayScreenResolver {
    static func resolve(
        windowFrame: CGRect?, mouseLocation: NSPoint, screens: [NSScreen] = NSScreen.screens
    ) -> NSScreen? {
        let frames = screens.map(\.frame)
        if let index = OverlayScreenGeometry.screenIndex(
            windowFrame: windowFrame, mouseLocation: mouseLocation, screens: frames)
        {
            return screens[index]
        }
        return NSScreen.main ?? screens.first
    }
}

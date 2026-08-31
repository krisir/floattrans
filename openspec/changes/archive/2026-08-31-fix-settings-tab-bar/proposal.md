## Why

Switching the interface language causes the settings window's top tab buttons to collapse into a compact overflow control, so the five pages are no longer all visible at once. The window is also taller than the content needs — 520×600 with a fixed SwiftUI frame — leaving empty space and blocking a shorter panel.

## What Changes

- Keep all five settings tabs visible as a single top tab bar after the interface language changes (Chinese ↔ English). Tabs MUST NOT collapse into a overflow/More control, sidebar, or picker.
- Relayout the tab bar when tab titles change length so English labels (`General`, `Translation`, `Overlay`, `Privacy`, `About`) and Chinese labels (`通用`, `翻译`, `悬浮窗`, `隐私`, `关于`) both fit.
- Reduce the settings window's default content height so the panel is shorter; pages that overflow (especially Overlay and Privacy) remain scrollable.
- Allow the window to be resized shorter than today's locked 600pt content frame (the window is already resizable in the style mask, but the SwiftUI view currently forces a fixed height).

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `settings`: tab bar stays fully expanded in both interface languages and after a live language switch; default settings window height is reduced and the content frame no longer prevents shrinking.

## Impact

- `Sources/LiveEnglish/SettingsUI.swift` — replace or restyle the collapsing `TabView` tab bar; lower the content height constraint.
- `Sources/LiveEnglish/App.swift` — match `presentSettings()` `NSWindow` content rect height to the new default.
- No persistence, menu bar, overlay, or translation-pipeline changes.

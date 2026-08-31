## Context

See proposal.md for motivation. `SettingsView` (`Sources/LiveEnglish/SettingsUI.swift`) uses a SwiftUI `TabView` with five `.tabItem` labels driven by `L10n` and the selected `UILanguage`. The view pins `.frame(width: 520, height: 600)`. `AppState.presentSettings()` (`Sources/LiveEnglish/App.swift`) creates a matching 520×600 `NSWindow` (resizable style mask). Pages already wrap content in `ScrollView`.

On recent macOS, `TabView`'s default style is adaptive. When tab titles change length after a live language switch (short Chinese labels → longer English labels), the system tab bar collapses into an overflow control instead of staying a five-button row. The fixed 600pt SwiftUI frame also stops the resizable window from shrinking.

## Goals / Non-Goals

**Goals:**
- A tab bar that always renders all five tabs as separate buttons, including immediately after `uiLanguage` changes.
- Default content size 520×480, with a flexible height so the user can shrink the window; overflowing pages keep scrolling.
- Same five pages, same controls, same `L10n` strings.

**Non-Goals:**
- No new tabs, no string copy changes, no persistence or menu-bar work.
- No change to how settings values write through to overlay / input / monitor.
- Do not rely on a particular macOS `TabView` style remaining non-adaptive.

## Decisions

### D1: Replace `TabView` tab items with an explicit custom tab bar

Drive page selection with `@State` (or an equivalent private enum) and render a top `HStack` of five buttons (existing SF Symbol + `L10n` title). Show the selected page below. Do not use `TabView` / `.tabItem` for chrome.

- Why: the collapse is `TabView`'s adaptive chrome, not missing strings. A custom bar has a stable layout that relayouts when titles change and cannot fold into More / sidebar / picker.
- Alternative considered: keep `TabView` and force a non-adaptive style (or `.id(uiLanguage)` to recreate it) — rejected; styles differ across macOS versions, and recreating the view can reset selection and still overflow once English titles are measured.
- Alternative considered: widen the window so English titles fit the system tab bar — rejected; collapse can still happen from style adaptation, and the user asked for a shorter panel, not a wider one.

### D2: Compact equal-width tab buttons, one row

Each tab button is `Label` (icon + title) in a compact control-size font, equally divided across the 520pt content width, with `lineLimit(1)` and a modest `minimumScaleFactor` so "Translation" fits without wrapping or overflowing. Selected tab uses accent / primary; others use secondary. A thin divider sits between the bar and the page.

- Alternative considered: `.pickerStyle(.segmented)` — rejected; five English titles are cramped in a segmented control and read as a picker, which the spec forbids as the collapsed form.

### D3: Flexible height instead of a locked 600pt frame

`SettingsView` uses `frame(minWidth: 520, idealWidth: 520, minHeight: 360, idealHeight: 480)` (width may stay fixed at 520 if that is simpler). `presentSettings()` opens the `NSWindow` at 520×480. Keep `.resizable`. Existing per-page `ScrollView`s cover Overlay / Privacy overflow.

- Alternative considered: keep a fixed frame but change 600 → 480 — rejected; the user also wants to be able to shorten the panel, which a fixed SwiftUI height prevents.

## Risks / Trade-offs

- [Custom tab bar is not native `NSTabView` accessibility] → Use `Button` + selected-state `accessibilityAddTraits(.isSelected)` (or equivalent) so VoiceOver can still move between tabs.
- [English titles may feel tight at 520pt] → Equal-width cells plus `minimumScaleFactor` keep one row; do not drop to icon-only.
- [Shorter default clips Overlay on first glance] → Accepted; the page already scrolls. 480 is enough for the General / Translation / About pages without scroll.

## Migration Plan

No data or settings-key changes. Ship the UI change; rollback is a rebuild of the previous version. Existing `uiLanguage` and other stored settings are untouched.

## Open Questions

None.

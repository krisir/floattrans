## 1. Custom tab bar

- [x] 1.1 In `SettingsUI.swift`, replace `TabView` / `.tabItem` with a private page enum and `@State` selection (default General)
- [x] 1.2 Render a top `HStack` of five equal-width buttons (existing SF Symbol + `L10n` title), compact font, `lineLimit(1)`, modest `minimumScaleFactor`, selected accent / unselected secondary, divider beneath
- [x] 1.3 Switch the page body on the selected enum so each page still shows only its own controls; preserve current page when `uiLanguage` changes
- [x] 1.4 Mark the selected tab with `accessibilityAddTraits(.isSelected)` (or equivalent)

## 2. Compact resizable window

- [x] 2.1 Change `SettingsView` from a locked 520×600 frame to `minWidth`/`idealWidth` 520 and `minHeight` 360 / `idealHeight` 480
- [x] 2.2 Update `AppState.presentSettings()` `NSWindow` content rect to 520×480; keep the resizable style mask
- [x] 2.3 Confirm Overlay and Privacy pages still scroll when content is taller than the visible area

## 3. Verify language switch and size

- [x] 3.1 Switch 中文 ↔ English on the General page and confirm all five tabs stay visible as separate buttons in one row, titles update, and the selected page does not reset
- [x] 3.2 Open Settings at 520×480 and shrink the window below 600pt; confirm the panel shortens and the current page remains usable

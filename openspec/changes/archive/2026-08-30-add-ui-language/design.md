## Context

See proposal.md — Why. Current chrome: `SettingsView` (`SettingsUI.swift`) is hard-coded Simplified Chinese across four tabs; `MenuBarExtra` in `App.swift` mixes English (`Pause` / `Resume` / `Quit`) with Chinese (`设置…`, `About 浮译`) and shows a fixed `中文 → English` caption; About is a separate `NSWindow` via `presentAbout()`. `SettingsStore` persists overlay/general prefs to UserDefaults but has no UI-language field. Main spec `openspec/specs/settings/spec.md` currently requires Chinese-only settings chrome and four tabs.

## Goals / Non-Goals

**Goals:**
- One persisted interface-language preference (中文 default, English optional) driving Settings + menu bar strings.
- Fifth Settings tab for About; remove About from the menu bar and stop opening the standalone About window from that entry point.
- Remove the menu-bar translation-direction caption.
- Immediate UI update when the language changes (no restart).

**Non-Goals:**
- Localizing Welcome / onboarding, overlay preview sample text, or diagnostic logs.
- Changing the translation pipeline direction (still Chinese → English).
- Full macOS `Localizable.xcstrings` / system locale auto-detection for v1 (explicit user choice only).
- Removing `AboutView` / `presentAbout` infrastructure if still useful internally — only the menu-bar entry and user-facing separate window flow go away.

## Decisions

### D1: Persist `uiLanguage` on `SettingsStore`
Add an enum (e.g. `UILanguage: chinese / english`) with a stable UserDefaults raw value; default `.chinese` when missing. Publish via `@Published` so SwiftUI menu + settings re-render. No migration beyond the default.

- Alternative: follow macOS system locale — rejected for v1; user asked for an explicit setting with Chinese default.

### D2: In-app string table, not Bundle localization catalogs
Keep a small `L10n` / `UIStrings` helper keyed by `UILanguage` (or methods on the enum) for menu bar + settings strings. Avoids `.xcstrings` / scheme localization complexity for two languages and matches the current hard-coded style.

- Alternative: `String(localized:)` + xcstrings — deferred; can replace the helper later without changing specs.

### D3: About as a fifth `TabView` page
Reuse `AboutView` (or extract shared content) inside Settings; localize its copy via the same string helper. Remove the menu-bar About button; `presentAbout()` need not be called from the menu (may delete the dedicated window path if unused).

### D4: Settings window title updates with language
`presentSettings` currently sets `window.title = "浮译设置"` once. On language change, update the existing `NSWindow.title` (observe `uiLanguage` or set from `SettingsView.onChange`) so English shows an English title (e.g. "FloatTrans Settings").

### D5: Menu bar observes language through `AppState` / `SettingsStore`
`MenuBarExtra` already reads `appDelegate.state`; bind labels to `state.settings.uiLanguage` (or a thin facade) so Pause/Resume/Settings/Quit strings refresh when the store publishes.

## Risks / Trade-offs

- [Hard-coded bilingual table drifts as UI grows] → Keep all menu/settings strings in one helper; tasks call out a sweep of `SettingsUI` + menu bar.
- [Standalone About window still reachable via old code paths] → Remove menu entry; leave or delete `presentAbout` only if nothing else calls it.
- [English About brand vs product name] → Spec allows 浮译 as brand; English descriptive sentences use "FloatTrans" where natural.

## Migration Plan

1. Ship `uiLanguage` defaulting to Chinese for existing installs (missing key → 中文).
2. No data wipe; overlay/privacy prefs unchanged.
3. Rollback: ignore the new key; UI returns to previous hard-coded Chinese settings + mixed menu (old binary).

## Open Questions

None — tab name (关于 / About) and Welcome out-of-scope were confirmed with the user.

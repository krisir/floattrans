# Design: Redesign settings UI (redesign-settings-ui)

## Context

Current state (see proposal.md — Why): `SettingsView` in `Sources/LiveEnglish/App.swift` is one `Form` with four `Section`s; `SettingsStore` (`Sources/LiveEnglish/Settings.swift`) persists each `@Published` property to `UserDefaults` on `didSet`; `OverlayCoordinator` (`Sources/LiveEnglish/Overlay.swift`) mirrors overlay settings as plain properties (`hideAfter: Double`, `neverHide: Bool`, `textSize`, `position`, `edgeDistance`, `behavior`) that the settings UI writes through on change. Enums `OverlayPosition` (topRight/bottomCenter/bottomRight), `OverlayBehavior` (replace/stack), `OverlayTextSize` persist their raw strings. The window is a plain titled `NSWindow` (520×680, content width 460) hosting the SwiftUI view; `LanguagePackSetupView` (macOS 26+) runs a `translationTask` to install/download zh→en resources. `InputCoordinator.delayMilliseconds` already exposes the 300/450/700 ms speed. All setting propagation (excluded app list → `input`/`monitor`) happens at the point of change.

Constraints: app targets macOS with a `#available(macOS 26.0)` gate for Translation framework; UI must not break on older macOS. The UI is to be Simplified Chinese (recorded assumption — the proposal's mockups and existing window title are Chinese; user allowed all-Chinese or all-English).

## Goals / Non-Goals

**Goals:**
- One window, four tab pages, per-page control sets and layout as specified in `specs/settings/spec.md`.
- `隐藏时间` stays a slider (5–60 秒) with the separate `永不隐藏` checkbox, per user decision; the slider's lower bound narrows from 3 to 5 seconds.
- Renamed overlay behavior option (`Keep Previous` → `Stack Below`) with migration of the stored string.
- All visible strings localized to Chinese; unified 150pt label column; permission and language-status presentation per spec.
- Immediate propagation of every setting to `OverlayCoordinator` / `InputCoordinator` / `AccessibilityMonitor`, preserving today's behavior.

**Non-Goals:**
- No changes to translation pipeline, sentence extraction, overlay rendering, or onboarding/about windows (their existing English strings stay; only the settings window is localized).
- No new settings features (shortcuts, translation API, multi-display, more positions) — the tab structure is designed to absorb them later, but none are added here.

## Decisions

### D1: Tab bar via plain SwiftUI `TabView`
Use a `TabView` with the default style inside the existing `NSHostingView`. In a regular titled window this renders a tab bar across the top with a divider — matching the mockup's `⚙ 通用 文 翻译 ◫ 悬浮窗 🔒 隐私` row. The macOS 15 `TabViewStyle.toolbar` (Settings-style tabs in the titlebar) is tempting but changes window chrome behavior per macOS version and complicates the fixed window frame; default `TabView` is version-stable and visually matches the proposed mockup.

- Alternative considered: custom `Picker` + manual page switching — rejected, reimplements tab semantics and accessibility for no gain.

### D2: Single fixed-size window, pages share the frame
Keep one `NSWindow`; `SettingsView` owns the `TabView` and each page sizes to the same frame (e.g. 520×600 content). Avoids per-tab window resizing and keeps `AppState.presentSettings`'s single-window reuse logic unchanged (only the content size constant changes).

### D3: Keep `hideAfter: Double` + `neverHide: Bool`; narrow the slider to 5–60
User decision: the hide-after slider stays, so no new enum is introduced. `SettingsStore` keeps `hideAfter: Double` and `neverHide: Bool` as today; the only model change is the `didSet` clamp range (3–60 → 5–60) and the init default stays 5. `OverlayCoordinator` keeps its existing two properties and semantics (永不隐藏 = never schedule auto-hide), so no plumbing change is required — the UI writes through exactly as today.

- Alternative considered: a discrete `HideAfter` enum (earlier draft) — rejected by the user's explicit decision; a slider over a continuous range is the requested interaction.

### D4: Migration in `SettingsStore.init` (one-time, in-process)
At init: re-clamp a stored `hideAfter` into 5–60 (old 3–4 second values become 5) and rewrite it; keep `neverHide` as-is. If `overlayBehavior` reads `"Keep Previous"`, map to `.stack` and rewrite as the new raw value. No keys are removed — `hideAfter` and `neverHide` keep their meaning, so migration is a pure value rewrite that is idempotent by construction.

### D5: Chinese display names computed, English raw values persisted
Keep raw strings in UserDefaults stable and version-tolerant: `OverlayPosition`/`OverlayBehavior`/`OverlayTextSize` each gain a computed `displayName` in Chinese (`右上 / 底部居中 / 右下`, `替换上一条 / 向下堆叠`, `小 / 中 / 大`). Only `OverlayBehavior`'s persisted raw value changes (`Keep Previous` → `Stack Below`) per the proposal; D4 migrates it.

### D6: Position visual picker — three custom-drawn thumbnails
An `HStack` of three buttons (~64×40 each) drawn with `RoundedRectangle` screen mockups: a filled bar/dot at the top-right, bottom-center, or bottom-right of each thumbnail, selected one accented with the window's accent color border. Bound to `overlayPosition` via the existing `Binding` that also writes `state.overlay.position`. Reuses `OverlayPosition.allCases` so adding positions later is one enum case.

- Alternative considered: SF Symbol per option (`rectangle.topright.inset.filled` etc.) — symbols don't communicate "screen position" as clearly as a thumbnail, and the user explicitly asked for the thumbnail interaction.

### D7: Segmented control for 翻译速度
`Picker` with `.pickerStyle(.segmented)` bound to the existing `state.input.delayMilliseconds` binding (tags 300/450/700). Three mutually exclusive options is the canonical segmented-control case; no model change.

### D8: Unified label column via one shared row component
A small `SettingsRow`/`SettingsLabel` view (in `Settings.swift` or a new `SettingsUI.swift`) that lays out `label.frame(width: 150, alignment: .trailing)` + control, used by all four pages. Single definition guarantees the spec's "same X on every page" without per-page discipline. Group headers use `.font(.headline)`-scale small caps styling distinct from the page title.

### D9: Language resource row rework
Replace `LanguagePackSetupView`'s always-visible install button with a state-driven row: query `LanguageAvailability` once on appear; `.installed` → `中文 → 英文 · 已就绪 ✓` (secondary, no button); `.unsupported` → short unsupported message; otherwise a 下载语言 button that starts the existing `translationTask` download flow, showing progress text until installed. Still gated by `#available(macOS 26.0)`; hidden entirely on older systems.

### D10: Compact permission status and privacy rows
General page: `state.permissionGranted ? small "✓ 已授权" secondary text : yellow hint + 打开系统设置 button (existing `state.requestPermission())`. Privacy page: one explanation line under the page title; `ExcludedAppRow` becomes icon + display name + circular `−` button (always visible — deterministic and discoverable; the mockup's "reveal on selection" is a refinement that adds hover/selection state complexity without behavioral benefit). Bundle ID never rendered.

## Risks / Trade-offs

- [Tab style renders differently on older macOS] → Default `TabView` style is available on all supported versions; verify visual result on the deployment target during implementation.
- [Legacy hide-after values below 5 (old range started at 3) jump to 5 on upgrade] → Accepted: user-specified floor of 5; a one-time re-clamp is the least surprising mapping, and 3–4 second values were rare non-defaults.
- [Chinese-only strings hardcode the UI language] → App is Chinese-first (title already 浮译设置); user accepted either all-Chinese or all-English; a future localization layer can refactor string constants without spec change.
- [Fixed window size may clip on smaller screens] → Current window is 520×680; new size 520×600 fits smaller viewport heights; keep the window resizable (style mask already includes it) so content can adapt.

## Migration Plan

1. Ship code with `SettingsStore.init` migration (D4) — runs once per install on first launch of the new version.
2. No server/backend data; no multi-step rollout. Rollback = reinstall previous build; `hideAfter`/`neverHide` survive unchanged (same keys, values only re-clamped), so rollback preserves settings; only a migrated `Stack Below` behavior value would read back as unknown in the old build and fall back to its default.

## Open Questions

None — all decisions above are within the specs' bounds.

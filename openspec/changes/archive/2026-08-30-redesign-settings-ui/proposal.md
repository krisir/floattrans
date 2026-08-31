## Why

The settings window is one long form that mixes every control type at once (toggles, sliders, pickers, checkboxes, status text, an app list), uses mixed language (Chinese window title, English labels), and permanently shows technical status noise ("Install Chinese → English Languages", "Languages ready.", "Granted" in green). Users cannot tell what is important, and the page will only get longer as features (shortcuts, translation API, multi-display) are added.

## What Changes

- Split the single settings form into **4 pages** behind a macOS-style toolbar tab bar: `通用 General / 翻译 Translation / 悬浮窗 Overlay / 隐私 Privacy`. Each page holds 3–6 settings.
- **Localize the settings UI to Simplified Chinese** (window title is already "浮译设置"): all labels, controls, buttons, and status text in Chinese; product name "浮译" used where the app is named. **BREAKING**: all visible English strings in `SettingsView` are replaced.
- **General page**: `启用实时翻译` toggle, `登录时启动` toggle, and a compact Accessibility status — small `✓ 已授权` when granted; only when permission is missing show a yellow hint and an `打开系统设置` button.
- **Translation page**: language direction shown as `中文 → 英文`; `翻译速度` becomes a **Segmented Control** with three options (`快速 / 均衡 / 舒缓`, mapping to existing 300/450/700 ms delays); `语言资源` row shows `中文 → 英文 · 已就绪 ✓` when installed, and a `下载语言` button only when not installed. The always-visible "Install … Languages" button and "Languages ready." status line are removed.
- **Overlay page**, grouped as `位置 / 外观 / 行为`:
  - `位置`: **visual picker** — 3 mini screen thumbnails (右上 / 底部居中 / 右下) instead of a dropdown.
  - `外观`: `文字大小` picker (`小 / 中 / 大`), `距顶部距离` slider (existing 0–300 range).
  - `行为`: `新翻译出现时` picker (`替换上一条 / 向下堆叠` — renames "Replace Previous / Keep Previous"), `隐藏时间` slider (5–60 秒), `永不隐藏` checkbox.
  - `预览悬浮窗` button.
  - The `永不隐藏` (Never hide) checkbox is **kept**; only its label is localized. `hideAfter` slider range narrows from 3–60 to **5–60 秒**. **BREAKING**: `overlayBehavior` raw value `Keep Previous` renamed `Stack Below` (persisted string changes, migration needed).
- **Privacy page**: one explanatory line under the section header ("浮译不会读取或翻译以下应用内的文本。"); each row shows only **icon + app name + remove button**; bundle ID and the repeated per-row sentence "Don't show translations in this app" are removed. `＋ 添加应用…` button retained.
- **Unified layout**: all pages use a consistent label column (150pt) with controls starting at the same X; page title shown once at top; group headers (`位置 / 外观 / 行为`) are small and secondary.

## Capabilities

### New Capabilities
- `settings`: the app's settings window — page/tab structure, control set per page, presentation of accessibility permission and language-resource status, and persistence of settings values (including migration of the changed keys).

### Modified Capabilities
<!-- No existing specs: openspec/specs/ is empty. -->

## Impact

- `Sources/LiveEnglish/App.swift` — `SettingsView` restructure, `ExcludedAppRow`, `LanguagePackSetupView`, `AppState.presentSettings` (window size for tabs).
- `Sources/LiveEnglish/Settings.swift` — `SettingsStore` published properties, `OverlayBehavior` rename, `hideAfter` clamp 3–60 → 5–60; UserDefaults keys `hideAfter`, `neverHide` keep their meaning (values re-clamped), `overlayBehavior` string changes.
- `Sources/LiveEnglish/Overlay.swift` — `OverlayCoordinator` consumes `hideAfter`/`neverHide` (unchanged semantics; 永不隐藏 = no auto-hide).
- `Sources/LiveEnglish/Input.swift` — `delayMilliseconds` already exposed; unchanged.
- UserDefaults migration for existing installs: `hideAfter` re-clamped into 5–60, `neverHide` kept, `Keep Previous` behavior string rewritten to `Stack Below`.

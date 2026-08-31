# Tasks: redesign-settings-ui

## 1. Model and persistence layer (`Settings.swift`)

- [x] 1.1 Rename `OverlayBehavior` case `stack` raw value `"Keep Previous"` → `"Stack Below"`; add Chinese `displayName` (`替换上一条 / 向下堆叠`) to `OverlayBehavior`, `OverlayPosition` (`右上 / 底部居中 / 右下`), and `OverlayTextSize` (`小 / 中 / 大`)
- [x] 1.2 Keep `SettingsStore.hideAfter: Double` and `neverHide: Bool`; narrow the `hideAfter` clamp from 3–60 to **5–60** in both `init` and `didSet`, with fresh default 5 and `neverHide` default off
- [x] 1.3 Add one-time migration in `SettingsStore.init`: re-clamp a stored `hideAfter` into 5–60 and rewrite it (keep `neverHide` as-is); rewrite `overlayBehavior` value `"Keep Previous"` → `"Stack Below"`

## 2. Overlay coordinator check (`Overlay.swift`)

- [x] 2.1 Confirm `OverlayCoordinator` needs no hide-after plumbing change: it keeps `hideAfter: Double` + `neverHide: Bool` with today's semantics (永不隐藏 = no auto-hide); the 5–60 clamp lives solely in `SettingsStore`

## 3. Shared settings UI scaffold (`App.swift` / new `SettingsUI.swift`)

- [x] 3.1 Restructure `SettingsView` into a `TabView` (default style) with four pages 通用 / 翻译 / 悬浮窗 / 隐私; each page shows its title once and small group headers (位置 / 外观 / 行为)
- [x] 3.2 Add a shared `SettingsRow` component enforcing the 150pt label column with controls starting at the same X; use it on all four pages
- [x] 3.3 Build the position visual picker: HStack of three ~64×40 custom-drawn screen thumbnails (top-right / bottom-center / bottom-right indicator), accent border on selection, bound to `overlayPosition` + `state.overlay.position` write-through

## 4. General page

- [x] 4.1 Render 启用实时翻译 and 登录时启动 toggles (existing bindings) with Chinese labels
- [x] 4.2 Render compact accessibility status: small secondary `✓ 已授权` when granted; yellow hint + 打开系统设置 button (calls `state.requestPermission()`) when missing

## 5. Translation page

- [x] 5.1 Show read-only direction `中文 → 英文`; 翻译速度 as a segmented `Picker` (快速/均衡/舒缓 → 300/450/700 ms) bound to `state.input.delayMilliseconds`
- [x] 5.2 Rework language-resource area into a state-driven row: query `LanguageAvailability` on appear; show `中文 → 英文 · 已就绪 ✓` when installed, a short message when unsupported, a 下载语言 button + progress text otherwise; keep the `#available(macOS 26.0)` gate and hide the row on older systems

## 6. Overlay page

- [x] 6.1 位置 group using the visual picker from 3.3
- [x] 6.2 外观 group: 文字大小 picker (小/中/大) and 距顶部距离 slider (0–300), both write-through to `state.overlay`
- [x] 6.3 行为 group: 新翻译出现时 picker (替换上一条 / 向下堆叠), 隐藏时间 slider (5–60 秒) and 永不隐藏 checkbox, all write-through to `state.overlay`
- [x] 6.4 Add 预览悬浮窗 button calling `state.showOverlayTest()`

## 7. Privacy page

- [x] 7.1 Add the single explanatory line 浮译不会读取或翻译以下应用内的文本。 under the page title
- [x] 7.2 Slim `ExcludedAppRow` to icon + app display name + circular remove button (no bundle ID, no per-row sentence); keep removal and ＋ 添加应用… flow propagating to `input.excludedBundleIDs` / `monitor.excludedBundleIDs`

## 8. Window sizing and polish

- [x] 8.1 Update `AppState.presentSettings` window frame to fit the tabbed layout (content ~520×600) without per-tab resizing
- [x] 8.2 Sweep `SettingsView` for any remaining English visible strings (all pages, buttons, statuses)

## 9. Verification

- [x] 9.1 Build the app (`Scripts/build-app.sh` or `swift build`) with no errors
- [x] 9.2 Launch the app, open settings, and verify: four tabs switch correctly; each page's controls match the spec (segmented speed, thumbnail position picker, 5–60 秒 hide slider + 永不隐藏 checkbox, compact privacy rows, unified 150pt alignment)
- [x] 9.3 Exercise write-through: change position/text size/distance/behavior/hide-after and confirm the overlay reflects it (via 预览悬浮窗); confirm 永不隐藏 keeps the overlay until manually closed
- [x] 9.4 Migration check: with legacy `hideAfter` (e.g. 3.5) and `Keep Previous` values in UserDefaults, launch and confirm `hideAfter` rewrites to ≥5 and behavior shows 向下堆叠; `neverHide` unchanged
- [x] 9.5 Permission status check: verify compact ✓ 已授权 when granted and yellow hint + 打开系统设置 when revoked

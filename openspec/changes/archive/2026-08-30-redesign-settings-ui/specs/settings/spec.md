## Purpose

Defines the behavior of the 浮译 (FloatTrans) settings window: its tab structure, the controls on each page, how permission and language-resource status are presented, and how settings values persist and migrate across app updates.

## ADDED Requirements

### Requirement: Settings window is organized into four tabs

The settings window presents its controls on four separate pages — 通用, 翻译, 悬浮窗, 隐私 — selected through a tab bar at the top of the window. Each page shows only its own controls, a page title, and its group headers; no other page's controls are visible.

#### Scenario: Opening settings shows the tab bar
- **WHEN** the user opens the settings window
- **THEN** the window is titled 浮译设置, shows a tab bar with the tabs 通用 / 翻译 / 悬浮窗 / 隐私, and displays the 通用 page by default

#### Scenario: Switching pages
- **WHEN** the user selects a different tab
- **THEN** the page content switches to that tab's page and the selected tab is highlighted

### Requirement: Settings UI is in Simplified Chinese

Every visible string in the settings window — tab titles, page titles, group headers, control labels, picker options, buttons, status text, and empty states — is written in Simplified Chinese. The app's product name 浮译 is used where the app is referred to by name.

#### Scenario: All pages localized
- **WHEN** any settings page is displayed
- **THEN** no visible English UI string remains on that page

### Requirement: General page shows core toggles and permission status compactly

The 通用 page contains the toggles 启用实时翻译 and 登录时启动, and an 辅助功能 (Accessibility) permission status area.

#### Scenario: Permission granted
- **WHEN** the app has accessibility permission and the user views the 通用 page
- **THEN** the permission area shows only a small ✓ 已授权 indicator in a secondary style, with no button

#### Scenario: Permission missing
- **WHEN** the app lacks accessibility permission and the user views the 通用 page
- **THEN** the permission area shows a yellow warning hint and a 打开系统设置 button that triggers the system permission request

### Requirement: Translation page shows direction, speed, and language resources

The 翻译 page shows the translation direction (中文 → 英文, read-only), the translation speed, and the language resource status.

#### Scenario: Speed is a segmented control
- **WHEN** the user views the 翻译 page
- **THEN** 翻译速度 is presented as a segmented control with exactly three options — 快速, 均衡, 舒缓 — and changing it takes effect for subsequent translations

#### Scenario: Languages installed
- **WHEN** the Chinese → English language resources are installed (where applicable) and the user views the 翻译 page
- **THEN** the 语言资源 row shows 中文 → 英文 · 已就绪 ✓ and no download button

#### Scenario: Languages not installed
- **WHEN** the Chinese → English language resources are not installed and the user views the 翻译 page
- **THEN** the 语言资源 row shows a download button; activating it downloads the resources and shows download progress, then shows 中文 → 英文 · 已就绪 ✓ on success

#### Scenario: Unsupported on this Mac
- **WHEN** Chinese → English translation is not supported on the current Mac
- **THEN** the 语言资源 row shows a brief message stating the pair is unsupported and no download button

#### Scenario: Language resources unavailable on older systems
- **WHEN** the running system does not support downloadable language resources
- **THEN** the 语言资源 row is hidden entirely

### Requirement: Overlay page groups position, appearance, and behavior

The 悬浮窗 page is organized into three groups — 位置, 外观, 行为 — and offers a 预览悬浮窗 button.

#### Scenario: Position is a visual picker
- **WHEN** the user views the 位置 group
- **THEN** position is chosen by selecting one of three mini screen thumbnails labeled 右上, 底部居中, 右下, and the selection immediately applies to the overlay

#### Scenario: Appearance controls
- **WHEN** the user views the 外观 group
- **THEN** it shows 文字大小 with options 小 / 中 / 大 and 距顶部距离 as a slider in the 0–300 range, both taking effect immediately

#### Scenario: New-translation behavior
- **WHEN** the user views the 行为 group
- **THEN** it shows 新翻译出现时 with exactly two options — 替换上一条 and 向下堆叠 — 隐藏时间 as a slider in the 5–60 second range, and a 永不隐藏 checkbox

#### Scenario: Preview overlay
- **WHEN** the user clicks 预览悬浮窗
- **THEN** a sample translation overlay appears on the main screen using the current position, size, distance, and behavior settings

### Requirement: Hide-after is a slider plus a never-hide checkbox

The overlay hide behavior is controlled by a 隐藏时间 slider (5–60 seconds) and a separate 永不隐藏 checkbox. When the checkbox is on, overlays are never auto-hidden; when off, each overlay auto-hides after the slider's number of seconds.

#### Scenario: Never hide
- **WHEN** 永不隐藏 is checked and a translation overlay is shown
- **THEN** the overlay remains visible until the user closes it, replaces it, or disables translation

#### Scenario: Timed hide
- **WHEN** 永不隐藏 is unchecked and a translation overlay is shown
- **THEN** the overlay auto-hides after the number of seconds shown on the 隐藏时间 slider (5–60)

#### Scenario: Slider bounds
- **WHEN** the user drags the 隐藏时间 slider
- **THEN** the value stays within 5 and 60 seconds

### Requirement: Privacy page lists excluded applications compactly

The 隐私 page shows a single explanatory line beneath the page title — 浮译不会读取或翻译以下应用内的文本。 — followed by one row per excluded application. Each row shows only the app icon, the app display name, and a remove control; bundle identifiers and per-row explanations are never shown.

#### Scenario: Removing an application
- **WHEN** the user activates the remove control on an application row
- **THEN** the row disappears, the app is no longer excluded, and translation resumes inside that app immediately

#### Scenario: Adding an application
- **WHEN** the user clicks the ＋ 添加应用… button and picks an application
- **THEN** a row for that application appears in the list and translation is suppressed inside it immediately

### Requirement: Settings persist and migrate cleanly

All settings persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: 启用实时翻译 on, 登录时启动 off, 翻译速度 均衡, 悬浮窗 position 底部居中, 文字大小 中, 距顶部距离 48, 新翻译出现时 替换上一条, 隐藏时间 5 秒, 永不隐藏 off, no excluded applications

### Requirement: Consistent control alignment

Every settings page lays out controls with a fixed-width label column (150pt) and controls starting at the same horizontal position; labels of equal length align across pages.

#### Scenario: Alignment across pages
- **WHEN** the user switches between any two settings pages
- **THEN** the label column width and control start position are identical on both pages

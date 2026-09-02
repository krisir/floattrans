## Purpose

Defines the behavior of the 浮译 (FloatTrans) settings window: its tab structure, default window size, interface language, the controls on each page, how permission and language-resource status are presented, and how settings values persist and migrate across app updates.

## Requirements

### Requirement: Settings window is organized into five tabs

The settings window presents its controls on five separate pages — 通用, 翻译, 悬浮窗, 隐私, 关于 (or General, Translation, Overlay, Privacy, About when the interface language is English) — selected through a tab bar at the top of the window. The tab bar SHALL show all five tabs as individual buttons in a single row. It SHALL NOT collapse any tab into an overflow control, sidebar, More menu, or single picker. Each page shows only its own controls, a page title, and its group headers; no other page's controls are visible.

#### Scenario: Opening settings shows the tab bar
- **WHEN** the user opens the settings window
- **THEN** the window title and tab bar use the selected interface language, all five tabs are visible as separate buttons (通用 / 翻译 / 悬浮窗 / 隐私 / 关于, or General / Translation / Overlay / Privacy / About), and the General page is displayed by default

#### Scenario: Switching pages
- **WHEN** the user selects a different tab
- **THEN** the page content switches to that tab's page and the selected tab is highlighted

#### Scenario: English tab titles stay in one row
- **WHEN** the interface language is English and the settings window is at its default width
- **THEN** General, Translation, Overlay, Privacy, and About are all visible as separate buttons in the top tab bar

### Requirement: Settings UI follows the selected interface language

Every visible string in the settings window — window title, tab titles, page titles, group headers, control labels, picker options, buttons, status text, and empty states — SHALL be shown in the selected interface language (Simplified Chinese or English). The product name 浮译 MAY remain as the brand where the app is named.

#### Scenario: Chinese interface
- **WHEN** the interface language is 中文 and any settings page is displayed
- **THEN** settings chrome strings are in Simplified Chinese

#### Scenario: English interface
- **WHEN** the interface language is English and any settings page is displayed
- **THEN** settings chrome strings are in English

#### Scenario: Language change applies immediately
- **WHEN** the user changes the interface language on the General page
- **THEN** the settings window title, tab titles, and visible page strings update to the new language without requiring an app restart, and the tab bar still shows all five tabs as separate buttons in a single row

### Requirement: Settings window uses a compact default height

The settings window SHALL open at a default content size of 520×480. Pages whose content exceeds the visible area SHALL remain scrollable. The window SHALL stay user-resizable and SHALL allow the user to shrink it below the previous 600pt content height.

#### Scenario: Default size on open
- **WHEN** the user opens the settings window
- **THEN** the content area is 520pt wide and 480pt tall

#### Scenario: Overflowing pages scroll
- **WHEN** the Overlay or Privacy page content is taller than the visible area
- **THEN** the page scrolls and no controls are permanently clipped off-screen

#### Scenario: User shortens the window
- **WHEN** the user resizes the settings window to a height below 600pt
- **THEN** the window shrinks and the current page remains usable by scrolling

### Requirement: General page shows core toggles and permission status compactly

The General page contains the toggles for enabling live translation and launch-at-login, an interface-language control with exactly two options — 中文 and English — and an Accessibility permission status area. Default interface language is 中文.

#### Scenario: Permission granted
- **WHEN** the app has accessibility permission and the user views the General page
- **THEN** the permission area shows only a small authorized indicator in a secondary style, with no button

#### Scenario: Permission missing
- **WHEN** the app lacks accessibility permission and the user views the General page
- **THEN** the permission area shows a yellow warning hint and a button that opens the system permission request

#### Scenario: Choosing interface language
- **WHEN** the user selects English (or 中文) in the interface-language control
- **THEN** the choice is persisted and the settings chrome and menu bar switch to that language immediately

### Requirement: Translation page shows direction, speed, and language resources

The 翻译 page shows the translation direction (中文 → 英文, read-only), the translation speed, and the language resource status. The selected translation speed SHALL be persisted and restored across app launches.

#### Scenario: Speed is a segmented control
- **WHEN** the user views the 翻译 page
- **THEN** 翻译速度 is presented as a segmented control with exactly three options — 快速, 均衡, 舒缓 — and changing it takes effect for subsequent translations

#### Scenario: Speed survives relaunch
- **WHEN** the user selects a translation speed, quits the app, and launches it again
- **THEN** the previously selected speed is displayed and used for subsequent translations

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

The 隐私 page shows a single explanatory line beneath the page title — 浮译不会读取或翻译以下应用内的文本。 — followed by one row per excluded application. Each row shows only the app icon, the app display name, and a remove control; bundle identifiers and per-row explanations are never shown. When an application is excluded, the system SHALL determine that exclusion before reading any Accessibility text from that application.

#### Scenario: Removing an application
- **WHEN** the user activates the remove control on an application row
- **THEN** the row disappears, the app is no longer excluded, and translation resumes inside that app immediately

#### Scenario: Adding an application
- **WHEN** the user clicks the ＋ 添加应用… button and picks an application
- **THEN** a row for that application appears in the list and translation is suppressed inside it immediately

#### Scenario: Excluded app text is not read
- **WHEN** the focused application has a bundle identifier in the excluded applications list
- **THEN** the system stops processing before requesting or reading the focused element's text through Accessibility

### Requirement: About tab presents app information

The Settings window SHALL include an 关于 / About tab that shows the product name 浮译 / FloatTrans, version, short description, license note, and the same repository and developer links previously shown in the standalone About window. The menu bar SHALL NOT open a separate About window.

#### Scenario: Viewing About
- **WHEN** the user selects the About tab
- **THEN** the page shows the app icon, product name, version, description, license note, and links for the repository and developer contact

#### Scenario: About content follows interface language
- **WHEN** the interface language is English
- **THEN** the About tab title and descriptive text are shown in English (product name may remain 浮译 where used as the brand)

### Requirement: Settings persist and migrate cleanly

All settings persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

### Requirement: Consistent control alignment

Every settings page lays out controls with a fixed-width label column (150pt) and controls starting at the same horizontal position; labels of equal length align across pages.

#### Scenario: Alignment across pages
- **WHEN** the user switches between any two settings pages
- **THEN** the label column width and control start position are identical on both pages

## MODIFIED Requirements

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

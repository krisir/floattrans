## MODIFIED Requirements

### Requirement: Translation page shows direction, speed, and language resources

The 翻译 page SHALL show 源语言 / Source Language and 目标语言 / Target Language pickers so the user can choose the translation pair. It SHALL NOT show a separate read-only 翻译方向 / Direction summary row. The page SHALL also show the translation speed and the language resource status. The selected translation speed SHALL be persisted and restored across app launches. On macOS 15 and later, the language-resource row SHALL be visible so the user can see installed, downloadable, or unsupported status.

#### Scenario: Direction summary is not shown
- **WHEN** the user views the 翻译 page
- **THEN** the page does not show a 翻译方向 / Direction row that restates the selected pair as read-only text

#### Scenario: Source and target language pickers are shown
- **WHEN** the user views the 翻译 page
- **THEN** the page shows Source Language and Target Language pickers with the current stored pair

#### Scenario: Changing source or target updates the pair
- **WHEN** the user selects a different source or target language
- **THEN** subsequent translations and language-resource status use the new pair, and the page still has no Direction summary row

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

#### Scenario: Language resources visible on macOS 15
- **WHEN** the app is running on macOS 15 or later and the user views the 翻译 page
- **THEN** the 语言资源 row is visible and is not hidden solely because the system is older than macOS 26

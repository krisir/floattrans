## MODIFIED Requirements

### Requirement: Translation page shows direction, speed, and language resources

The 翻译 page shows the translation direction (中文 → 英文, read-only), the translation speed, and the language resource status. The selected translation speed SHALL be persisted and restored across app launches. On macOS 15 and later, the language-resource row SHALL be visible so the user can see installed, downloadable, or unsupported status.

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

## ADDED Requirements

### Requirement: Onboarding can install language resources on macOS 15

The first-run welcome flow SHALL offer Chinese → English language-resource install on macOS 15 and later, using the same installed / downloading / unsupported outcomes as Settings.

#### Scenario: Welcome shows language install on Sequoia
- **WHEN** a first-run user on macOS 15 reaches the permission / language step of onboarding
- **THEN** they can start Chinese → English language-resource installation from that step

#### Scenario: Unsupported Mac during onboarding
- **WHEN** Chinese → English is unsupported on the current Mac and the user is in onboarding
- **THEN** the language step shows that the pair is unsupported and does not present a working install action as if download were possible

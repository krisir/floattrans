## ADDED Requirements

### Requirement: Settings window is organized into five tabs

The settings window presents its controls on five separate pages — 通用, 翻译, 悬浮窗, 隐私, 关于 (or General, Translation, Overlay, Privacy, About when the interface language is English) — selected through a tab bar at the top of the window. Each page shows only its own controls, a page title, and its group headers; no other page's controls are visible.

#### Scenario: Opening settings shows the tab bar
- **WHEN** the user opens the settings window
- **THEN** the window title and tab bar use the selected interface language, the tabs are 通用 / 翻译 / 悬浮窗 / 隐私 / 关于 (or General / Translation / Overlay / Privacy / About), and the General page is displayed by default

#### Scenario: Switching pages
- **WHEN** the user selects a different tab
- **THEN** the page content switches to that tab's page and the selected tab is highlighted

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
- **THEN** the settings window title, tab titles, and visible page strings update to the new language without requiring an app restart

### Requirement: About tab presents app information

The Settings window SHALL include an 关于 / About tab that shows the product name 浮译 / FloatTrans, version, short description, license note, and the same repository and developer links previously shown in the standalone About window. The menu bar SHALL NOT open a separate About window.

#### Scenario: Viewing About
- **WHEN** the user selects the About tab
- **THEN** the page shows the app icon, product name, version, description, license note, and links for the repository and developer contact

#### Scenario: About content follows interface language
- **WHEN** the interface language is English
- **THEN** the About tab title and descriptive text are shown in English (product name may remain 浮译 where used as the brand)

## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: Settings window is organized into four tabs
**Reason**: Replaced by the five-tab layout that adds 关于 / About.
**Migration**: Use Requirement "Settings window is organized into five tabs".

### Requirement: Settings UI is in Simplified Chinese
**Reason**: Settings chrome is no longer Chinese-only; it follows the selected interface language.
**Migration**: Use Requirement "Settings UI follows the selected interface language".

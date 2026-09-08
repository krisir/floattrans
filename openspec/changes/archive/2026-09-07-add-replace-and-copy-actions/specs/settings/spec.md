## ADDED Requirements

### Requirement: Translation page includes Replace Original and Copy Translation controls

The 翻译 page SHALL include toggles for 替换原文 / Replace Original and 复制译文 / Copy Translation, each with a shortcut control. All visible labels SHALL follow the selected interface language. Changing a toggle or shortcut SHALL take effect without requiring an app restart.

#### Scenario: Action controls are visible
- **WHEN** the user views the Translation page
- **THEN** the page shows Replace Original and Copy Translation switches and the current shortcut for each

#### Scenario: Controls follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Translation page
- **THEN** the Replace Original and Copy Translation labels and shortcut labels are shown in Simplified Chinese

#### Scenario: Controls follow English interface
- **WHEN** the interface language is English and the user views the Translation page
- **THEN** the Replace Original and Copy Translation labels and shortcut labels are shown in English

#### Scenario: User records a new shortcut
- **WHEN** the user records a new key combination in either shortcut control
- **THEN** that combination is shown as the current shortcut for that action and is used for subsequent presses of that action

### Requirement: Replace Original and Copy Translation settings persist and default safely

Replace Original, Copy Translation, and their shortcuts SHALL persist across app launches. Fresh installs and existing installs without stored values SHALL default to both actions off, replace shortcut Control-Shift-Return, and copy shortcut Control-Shift-C, without changing unrelated existing settings.

#### Scenario: Action settings survive relaunch
- **WHEN** the user changes Replace Original, Copy Translation, or either shortcut, quits the app, and launches it again
- **THEN** the previous values are restored

#### Scenario: Fresh install action defaults
- **WHEN** no prior Replace Original or Copy Translation settings exist
- **THEN** both actions are off, the replace shortcut is Control-Shift-Return, and the copy shortcut is Control-Shift-C

#### Scenario: Existing install receives action defaults
- **WHEN** an existing install launches without stored Replace Original or Copy Translation settings
- **THEN** missing values use the fresh-install defaults without changing unrelated existing settings

## MODIFIED Requirements

### Requirement: Settings persist and migrate cleanly

All settings persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文. Missing Replace Original and Copy Translation values default to off with replace shortcut Control-Shift-Return and copy shortcut Control-Shift-C.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications, Replace Original off, Copy Translation off, replace shortcut Control-Shift-Return, copy shortcut Control-Shift-C

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

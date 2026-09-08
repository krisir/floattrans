## ADDED Requirements

### Requirement: Translation page includes translation timing

The 翻译 page SHALL include a 翻译时机 / Translation Timing control with exactly three options: 超时翻译 / On Pause, 完整句子翻译 / Complete Sentence, and 快捷键触发翻译 / On Shortcut. All visible labels SHALL follow the selected interface language. Changing the mode SHALL take effect without requiring an app restart. When On Shortcut is selected, the page SHALL show a translate-shortcut control; that control MAY be hidden in the other modes.

#### Scenario: Timing control is visible
- **WHEN** the user views the Translation page
- **THEN** the page shows Translation Timing with the three options and the currently selected mode

#### Scenario: Timing labels follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Translation page
- **THEN** the timing label and options are shown in Simplified Chinese

#### Scenario: Timing labels follow English interface
- **WHEN** the interface language is English and the user views the Translation page
- **THEN** the timing label and options are shown in English

#### Scenario: Shortcut recorder appears for On Shortcut
- **WHEN** the user selects On Shortcut
- **THEN** a translate-shortcut control is shown and recording a combination uses that combination for subsequent translate presses

#### Scenario: Shortcut recorder hidden for other modes
- **WHEN** the user selects On Pause or Complete Sentence
- **THEN** the translate-shortcut control is not shown

### Requirement: Translation timing persists and defaults to On Pause

Translation timing and the translate shortcut SHALL persist across app launches. Fresh installs and existing installs without stored values SHALL default to On Pause and translate shortcut Control-Shift-T, without changing unrelated existing settings. The default translate shortcut MUST NOT be Control-Option-Return.

#### Scenario: Timing survives relaunch
- **WHEN** the user changes translation timing or the translate shortcut, quits the app, and launches it again
- **THEN** the previous values are restored

#### Scenario: Fresh install timing defaults
- **WHEN** no prior translation-timing settings exist
- **THEN** timing is On Pause and the translate shortcut is Control-Shift-T

#### Scenario: Existing install receives timing defaults
- **WHEN** an existing install launches without stored translation-timing settings
- **THEN** timing is On Pause and the translate shortcut is Control-Shift-T, without changing stored Replace Original, Copy Translation, or their shortcuts

### Requirement: Translation speed applies only in On Pause mode

The existing 翻译速度 / Translation Speed control SHALL continue to set the pause used for On Pause timing. Changing speed SHALL NOT delay Complete Sentence or On Shortcut translation.

#### Scenario: Speed still changes the pause
- **WHEN** timing is On Pause and the user changes translation speed
- **THEN** subsequent pause-based translations use the new speed

#### Scenario: Speed ignored for other modes
- **WHEN** timing is Complete Sentence or On Shortcut
- **THEN** translation starts when that mode’s trigger fires, without waiting for the translation-speed pause

## MODIFIED Requirements

### Requirement: Settings persist and migrate cleanly

All settings persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文. Missing Replace Original and Copy Translation values default to off with replace shortcut Control-Shift-Return and copy shortcut Control-Shift-C. Missing translation-timing values default to On Pause with translate shortcut Control-Shift-T.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, translation timing On Pause, translate shortcut Control-Shift-T, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications, Replace Original off, Copy Translation off, replace shortcut Control-Shift-Return, copy shortcut Control-Shift-C

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

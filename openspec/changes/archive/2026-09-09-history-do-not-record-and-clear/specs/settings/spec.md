## ADDED Requirements

### Requirement: History page retention picker includes Do Not Record

The Settings History page SHALL present retention as a picker whose options include 不记录 / Do Not Record plus the existing timed and forever options. Changing the selection SHALL take effect without requiring an app restart. All visible labels SHALL follow the selected interface language.

#### Scenario: Picker shows Do Not Record
- **WHEN** the user views the History page
- **THEN** the retention picker includes 不记录 when the interface language is 中文, or Do Not Record when it is English

#### Scenario: Selecting Do Not Record applies immediately
- **WHEN** the user selects Do Not Record
- **THEN** subsequent completed translations are not stored, without requiring an app restart

### Requirement: History page can delete all records with confirmation

The History page SHALL include a 删除历史记录 / Delete History control. Activating it SHALL present a confirmation dialog with a cancel action and a confirm action. Confirming SHALL remove every local history record and refresh the page to the empty state. Canceling SHALL close the dialog and leave records unchanged. Control and dialog strings SHALL follow the selected interface language. When the list is empty, the control SHALL be disabled.

#### Scenario: Delete control is visible
- **WHEN** the user views the History page and history contains at least one row
- **THEN** the page shows a Delete History control that can be activated

#### Scenario: Confirmation is required
- **WHEN** the user activates Delete History
- **THEN** a confirmation dialog is shown and no rows are deleted until the user confirms

#### Scenario: Confirm clears the list
- **WHEN** the user confirms the delete dialog
- **THEN** all history rows are gone and the page shows the empty-history message

#### Scenario: Cancel leaves the list unchanged
- **WHEN** the user cancels the delete dialog
- **THEN** the dialog closes and the previously visible rows remain

#### Scenario: Empty list disables delete
- **WHEN** the History page has no rows
- **THEN** the Delete History control is disabled

## MODIFIED Requirements

### Requirement: Settings persist and migrate cleanly

All settings SHALL persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文. Missing Replace Original and Copy Translation values default to off with replace shortcut Option-Shift-`[` and copy shortcut Option-Shift-`]`. Missing translation-timing values default to On Pause with translate shortcut Control-Shift-T. Missing history-retention values SHALL default to Do Not Record. An existing stored history-retention value SHALL be kept.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, translation timing On Pause, translate shortcut Control-Shift-T, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications, Replace Original off, Copy Translation off, replace shortcut Option-Shift-`[`, copy shortcut Option-Shift-`]`, history retention Do Not Record

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

#### Scenario: Existing install without history retention
- **WHEN** an existing install has no stored history-retention value
- **THEN** history retention defaults to Do Not Record and is written on first save or first change

#### Scenario: Stored history retention is not overwritten
- **WHEN** an existing install already has a stored history-retention value
- **THEN** that stored value is kept and is not replaced with Do Not Record

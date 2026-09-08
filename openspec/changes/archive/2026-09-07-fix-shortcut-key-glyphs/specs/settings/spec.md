## ADDED Requirements

### Requirement: Shortcut labels show punctuation keys as characters

Recorded and default shortcuts SHALL display ANSI punctuation keys as their unshifted characters, not as a numeric `Key N` fallback. Shift and Option in the combination MUST still appear as modifier glyphs; they MUST NOT change `[` into `{` or `]` into `}` in the label.

#### Scenario: Option-Shift-left-bracket displays as brackets
- **WHEN** the replace shortcut is Option-Shift-`[`
- **THEN** the shortcut control shows `⌥⇧[` and does not show `Key 30` or `⌥⇧{`

#### Scenario: Option-Shift-right-bracket displays as brackets
- **WHEN** the copy shortcut is Option-Shift-`]`
- **THEN** the shortcut control shows `⌥⇧]` and does not show a numeric key fallback or `⌥⇧}`

## MODIFIED Requirements

### Requirement: Replace Original and Copy Translation settings persist and default safely

Replace Original, Copy Translation, and their shortcuts SHALL persist across app launches. Fresh installs and existing installs without stored values SHALL default to both actions off, replace shortcut Option-Shift-`[`, and copy shortcut Option-Shift-`]`, without changing unrelated existing settings.

#### Scenario: Action settings survive relaunch
- **WHEN** the user changes Replace Original, Copy Translation, or either shortcut, quits the app, and launches it again
- **THEN** the previous values are restored

#### Scenario: Fresh install action defaults
- **WHEN** no prior Replace Original or Copy Translation settings exist
- **THEN** both actions are off, the replace shortcut is Option-Shift-`[`, and the copy shortcut is Option-Shift-`]`

#### Scenario: Existing install receives action defaults
- **WHEN** an existing install launches without stored Replace Original or Copy Translation settings
- **THEN** missing values use the fresh-install defaults without changing unrelated existing settings

#### Scenario: Stored shortcuts are not overwritten
- **WHEN** an existing install already has stored replace or copy shortcut key codes
- **THEN** those stored combinations are kept and are not replaced with Option-Shift-bracket defaults

### Requirement: Settings persist and migrate cleanly

All settings persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文. Missing Replace Original and Copy Translation values default to off with replace shortcut Option-Shift-`[` and copy shortcut Option-Shift-`]`. Missing translation-timing values default to On Pause with translate shortcut Control-Shift-T.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, translation timing On Pause, translate shortcut Control-Shift-T, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications, Replace Original off, Copy Translation off, replace shortcut Option-Shift-`[`, copy shortcut Option-Shift-`]`

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

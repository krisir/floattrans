## ADDED Requirements

### Requirement: Translation page Speech section shows only the auto-speak switch
The Translation page SHALL include a Speech section whose only control is a switch that enables or disables reading completed translations aloud. The section SHALL NOT show a voice picker, speaking-rate control, volume control, or auto-speak policy picker. All visible labels SHALL follow the selected interface language.

#### Scenario: Only the auto-speak switch is visible
- **WHEN** the user views the Translation page
- **THEN** the Speech section shows the 朗读翻译结果 / Read Translations Aloud switch and does not show controls for voice, speaking rate, volume, or auto-speak policy

#### Scenario: Speech labels follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Speech section
- **THEN** the section and switch labels are shown in Simplified Chinese

#### Scenario: Speech labels follow English interface
- **WHEN** the interface language is English and the user views the Speech section
- **THEN** the section and switch labels are shown in English

#### Scenario: Turning the switch off stops speech
- **WHEN** a translation is being spoken and the user turns the auto-speak switch off
- **THEN** the current speech stops immediately and later translations are not spoken while the switch remains off

## MODIFIED Requirements

### Requirement: Settings persist and migrate cleanly

All settings persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文. Missing Replace Original and Copy Translation values default to off with replace shortcut Control-Shift-Return and copy shortcut Control-Shift-C. The auto-speak switch persists independently. Previously stored speech voice, speaking rate, volume, and auto-speak policy values SHALL be ignored and SHALL NOT restore removed Settings controls.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications, Replace Original off, Copy Translation off, replace shortcut Control-Shift-Return, copy shortcut Control-Shift-C, auto-speak off

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

#### Scenario: Auto-speak switch survives relaunch
- **WHEN** the user changes the auto-speak switch, quits the app, and launches it again
- **THEN** the previous switch value is restored

#### Scenario: Leftover speech customization keys are ignored
- **WHEN** an existing install has stored speech voice, speaking rate, volume, or auto-speak policy values
- **THEN** those values do not appear as Settings controls and do not change playback away from the built-in voice, rate, and volume, or the switch-only auto-speak gate

## REMOVED Requirements

### Requirement: Translation page includes speech controls
**Reason**: Voice, speaking rate, volume, and auto-speak policy are no longer user-facing. The Speech section keeps only the auto-speak switch.
**Migration**: Use the 朗读翻译结果 / Read Translations Aloud switch. Playback uses the app's built-in English voice, rate, and volume. The switch is the only auto-speak gate.

### Requirement: Speech settings persist and default safely
**Reason**: The remaining auto-speak switch is covered by the shared settings persistence requirement. Voice, rate, volume, and auto-speak policy are no longer settings.
**Migration**: Persist only the auto-speak switch. Ignore leftover stored keys for the removed controls.

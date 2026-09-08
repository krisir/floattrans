## MODIFIED Requirements

### Requirement: Translation speech uses local macOS speech output
When auto-speak is enabled, the system SHALL read completed English translation text aloud using local macOS speech capabilities. Playback SHALL use a built-in English voice, speaking rate, and volume chosen by the app. The system SHALL NOT require the user to select a voice, rate, or volume. Speech playback SHALL NOT send translated text to any additional remote service beyond the translation flow already used to produce the displayed text.

#### Scenario: Completed translation is spoken
- **WHEN** live translation produces an English overlay and auto-speak is enabled
- **THEN** the system reads the English translation aloud through the current default output device using the built-in voice, rate, and volume

#### Scenario: Speech remains local
- **WHEN** the system reads a translation aloud
- **THEN** speech synthesis uses on-device macOS speech output and does not submit the translated text to an extra speech service

#### Scenario: New speech replaces previous speech
- **WHEN** a new translation is permitted to speak while a previous translation is still being spoken
- **THEN** the previous speech stops and the newest completed translation is spoken

#### Scenario: No voice, rate, or volume selection is required
- **WHEN** auto-speak is enabled and a translation is spoken
- **THEN** playback proceeds without any user-selected voice, speaking rate, or volume

## REMOVED Requirements

### Requirement: Auto-speak policy is user selectable
**Reason**: The Speech section now has only an on/off switch. A three-way auto-speak policy picker was extra settings surface, and stored policy values would disagree with that simpler control.
**Migration**: When the auto-speak switch is on, completed translations are spoken. When the switch is off, translations are not spoken. Users who previously chose Quiet Only or Never lose that stored choice.

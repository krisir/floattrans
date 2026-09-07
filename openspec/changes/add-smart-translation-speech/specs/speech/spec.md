## Purpose

Defines FloatTrans speech playback for completed translations, including local text-to-speech output, user-controlled auto-speak behavior, and safeguards that avoid speaking over active media or communication sessions.

## ADDED Requirements

### Requirement: Translation speech uses local macOS speech output
When speech is enabled, the system SHALL be able to read completed English translation text aloud using local macOS speech capabilities. Speech playback SHALL NOT send translated text to any additional remote service beyond the translation flow already used to produce the displayed text.

#### Scenario: Completed translation is spoken
- **WHEN** live translation produces an English overlay and speech is enabled with an auto-speak policy that permits playback
- **THEN** the system reads the English translation aloud through the current default output device

#### Scenario: Speech remains local
- **WHEN** the system reads a translation aloud
- **THEN** speech synthesis uses on-device macOS speech output and does not submit the translated text to an extra speech service

#### Scenario: New speech replaces previous speech
- **WHEN** a new translation is permitted to speak while a previous translation is still being spoken
- **THEN** the previous speech stops and the newest completed translation is spoken

### Requirement: User can stop speech playback
The system SHALL provide a way for speech playback to stop immediately when live translation is disabled, paused, or the user explicitly stops the current spoken output.

#### Scenario: Translation is paused during speech
- **WHEN** a translation is being spoken and the user pauses live translation
- **THEN** the current speech stops immediately

#### Scenario: Speech is disabled during speech
- **WHEN** a translation is being spoken and the user turns speech off
- **THEN** the current speech stops immediately and later translations are not spoken while speech remains off

### Requirement: Auto-speak respects audio context
Before automatically speaking a translation, the system SHALL classify the current audio context as `silent`, `mediaPlayback`, `communication`, or `unknownAudio`. The default auto-speak policy SHALL speak only when the context is `silent`.

#### Scenario: Mac is quiet
- **WHEN** speech is enabled, auto-speak is set to only speak when the Mac is quiet, and no other application appears to be using audio input or output
- **THEN** the completed English translation is spoken

#### Scenario: Media is playing
- **WHEN** speech is enabled, auto-speak is set to only speak when the Mac is quiet, and another application is actively producing audio output
- **THEN** the overlay still appears but the translation is not spoken

#### Scenario: Communication session is active
- **WHEN** speech is enabled, auto-speak is set to only speak when the Mac is quiet, and another process appears to be actively using both audio input and output or is an active known communication application
- **THEN** the overlay still appears but the translation is not spoken

#### Scenario: Audio context cannot be classified safely
- **WHEN** speech is enabled, auto-speak is set to only speak when the Mac is quiet, and the audio context cannot be confidently classified as silent
- **THEN** the overlay still appears but the translation is not spoken

### Requirement: Auto-speak policy is user selectable
The system SHALL support three auto-speak policies: speak only when the Mac is quiet, always speak, and never auto-speak. The quiet-only policy SHALL be the default for fresh installs.

#### Scenario: Always speak
- **WHEN** speech is enabled, auto-speak is set to always speak, and a translation completes
- **THEN** the translation is spoken regardless of other audio activity

#### Scenario: Never auto-speak
- **WHEN** speech is enabled, auto-speak is set to never auto-speak, and a translation completes
- **THEN** the overlay appears and the translation is not spoken automatically

#### Scenario: Speech disabled overrides auto-speak policy
- **WHEN** speech is disabled and a translation completes
- **THEN** the translation is not spoken regardless of the selected auto-speak policy

### Requirement: Skipped speech can be indicated without interrupting the user
When speech is skipped because the current audio context blocks playback, the system MAY show a compact muted indication near the overlay. If shown, the indication SHALL be non-blocking and SHALL NOT require user dismissal.

#### Scenario: Speech skipped by quiet-only policy
- **WHEN** a translation appears and speech is skipped because other audio is active
- **THEN** the overlay remains visible and any skipped-speech indication is compact, transient or passive, and does not obscure the translation text

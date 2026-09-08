## ADDED Requirements

### Requirement: Translation page includes speech controls
The Translation page SHALL include a Speech section with controls for enabling speech, selecting a voice or locale, adjusting speaking rate, adjusting volume, and choosing the auto-speak policy. All visible labels and option names SHALL follow the selected interface language.

#### Scenario: Speech controls are visible
- **WHEN** the user views the Translation page
- **THEN** the page shows a Speech section with controls for speech enablement, voice or locale, speaking rate, volume, and auto-speak policy

#### Scenario: Speech controls follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Speech section
- **THEN** the section labels and options are shown in Simplified Chinese

#### Scenario: Speech controls follow English interface
- **WHEN** the interface language is English and the user views the Speech section
- **THEN** the section labels and options are shown in English

### Requirement: Speech settings persist and default safely
Speech settings SHALL persist across app launches. Fresh installs SHALL default to speech enabled off, English voice or locale `en-US`, medium speaking rate, normal volume, and auto-speak policy set to only speak when the Mac is quiet.

#### Scenario: Speech settings survive relaunch
- **WHEN** the user changes any speech setting, quits the app, and launches it again
- **THEN** the previous speech setting values are restored

#### Scenario: Fresh install speech defaults
- **WHEN** no prior speech settings exist
- **THEN** defaults are: speech off, voice or locale en-US, medium speaking rate, normal volume, and auto-speak only when the Mac is quiet

#### Scenario: Existing install receives speech defaults
- **WHEN** an existing install launches without stored speech settings
- **THEN** missing speech settings use the fresh install defaults without changing unrelated existing settings

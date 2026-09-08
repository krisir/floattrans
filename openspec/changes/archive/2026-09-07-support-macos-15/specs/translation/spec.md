## Purpose

Provides on-device Chinese-to-English translation of the user's current sentence using macOS system translation, from macOS 15 onward, without sending the text to a third-party translation service.

## ADDED Requirements

### Requirement: Supported systems use on-device system translation

On macOS 15 and later, when Chinese → English language resources are installed and the pair is supported, the system SHALL translate completed Chinese input with on-device system translation. The original and translated sentence content SHALL NOT be submitted to a remote translation API. The system SHALL NOT use a canned or prefix-only demo translation as the production result on these systems.

#### Scenario: Installed languages produce English
- **WHEN** a user on macOS 15 or later has Chinese → English language resources installed and types a completed Chinese sentence in a supported text field
- **THEN** the overlay shows an English translation of that sentence rather than the original Chinese prefixed with demo text

#### Scenario: Translation stays on device
- **WHEN** the system translates a sentence
- **THEN** the sentence is processed by on-device system translation and is not sent to a third-party translation HTTP API

### Requirement: Missing or unsupported language resources do not fake a translation

When Chinese → English resources are not installed, still downloading, or reported as unsupported on the current Mac, the system SHALL NOT display a demo or placeholder English string as if it were a real translation. Overlay and input monitoring MAY continue to run.

#### Scenario: Languages not installed
- **WHEN** the user types Chinese and Chinese → English resources are not installed
- **THEN** no overlay presents a fabricated English result such as a prefix plus the original sentence

#### Scenario: Pair unsupported on this Mac
- **WHEN** the system reports Chinese → English as unsupported
- **THEN** typing Chinese does not produce a translation overlay, and the rest of the app remains usable

### Requirement: Translation continues while settings and the menu are closed

On-device translation SHALL remain available while the menu bar menu and settings window are closed. Closing those surfaces SHALL NOT end the translation capability for the rest of the session.

#### Scenario: Menu closed still translates
- **WHEN** the app is enabled, language resources are installed, and the user is typing in another app with the FloatTrans menu and settings window closed
- **THEN** completed Chinese sentences still receive English overlay translations

#### Scenario: Settings closed after installing languages
- **WHEN** the user installs language resources from Settings and then closes the settings window
- **THEN** subsequent completed Chinese sentences still translate without requiring Settings to stay open

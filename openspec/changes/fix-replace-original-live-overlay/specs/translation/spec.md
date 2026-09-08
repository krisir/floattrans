## MODIFIED Requirements

### Requirement: Replacement of the focused field happens only on the replace shortcut

When Replace Original is on, a successful translation MUST NOT modify the focused input field by itself. The system SHALL replace the current source fragment in the focused field with the English translation only after the user presses the configured replace shortcut. The current source fragment is the Chinese text that produced the overlay translation, including a trailing terminator when one is present. Any text before that fragment SHALL be left unchanged. The shortcut MUST work while another application is focused and MUST NOT steal focus from the input field. When Replace Original is off, pressing the replace shortcut MUST NOT change the field.

#### Scenario: Translation does not rewrite the field automatically
- **WHEN** Replace Original is on and a Chinese fragment is translated
- **THEN** the focused input field still contains the original Chinese and the overlay shows the English result

#### Scenario: Replace shortcut replaces an in-progress fragment
- **WHEN** Replace Original is on, the overlay shows a translation of Chinese that does not yet end with a terminator, the field still contains that fragment, and the user presses the replace shortcut
- **THEN** that fragment is replaced with the English translation and earlier text in the field is preserved

#### Scenario: Replace shortcut replaces a completed sentence
- **WHEN** Replace Original is on, a completed sentence has been translated, the field still contains that source sentence, and the user presses the replace shortcut
- **THEN** that source sentence (including its terminator) is replaced with the English translation and earlier text in the field is preserved

#### Scenario: Replace shortcut does nothing without a ready translation
- **WHEN** Replace Original is on and the user presses the replace shortcut but there is no current translation for the focused fragment
- **THEN** the focused field is left unchanged

#### Scenario: Replace shortcut ignored when Replace Original is off
- **WHEN** Replace Original is off and the user presses the replace shortcut
- **THEN** the focused field is left unchanged

#### Scenario: Replace shortcut ignored while translation is paused
- **WHEN** live translation is paused and the user presses the replace shortcut
- **THEN** the focused field is left unchanged

### Requirement: Replace Original does not overwrite stale or unwritable fields

The system SHALL write the translation only if the focused field still contains the same source fragment that was translated. If the field cannot be written, or that source is no longer present, the original text SHALL remain and the overlay translation SHALL still be shown.

#### Scenario: User kept typing after translation
- **WHEN** a fragment has been translated and the user changes that fragment before pressing the replace shortcut
- **THEN** pressing the shortcut does not write the stale translation into the field

#### Scenario: Field cannot be written
- **WHEN** the user presses the replace shortcut and the focused field rejects the write
- **THEN** the original text remains and the overlay still shows the translation

## ADDED Requirements

### Requirement: Replace Original uses pause-based live translation

When Replace Original is on and live translation is enabled, the system SHALL translate the current Chinese fragment after the configured typing pause, whether or not the fragment ends with a sentence terminator. A terminator such as `。` `.` `？` `?` `！` `!` or a newline MAY be present and SHALL still be included when replacing. When Replace Original is off, pause-based live translation SHALL remain unchanged, including when Copy Translation is on.

#### Scenario: Incomplete sentence still shows overlay
- **WHEN** Replace Original is on and the user pauses after typing Chinese that does not end with a sentence terminator
- **THEN** the overlay shows an English translation of that in-progress fragment

#### Scenario: Completed sentence still shows overlay
- **WHEN** Replace Original is on and the user types a Chinese sentence followed by a terminator
- **THEN** the overlay shows an English translation of that completed sentence

#### Scenario: Setting off keeps live pause translation
- **WHEN** Replace Original is off and the user pauses while typing Chinese
- **THEN** the overlay still updates using the existing pause-based translation behavior

## REMOVED Requirements

### Requirement: Replace Original waits for a completed sentence before translating

**Reason**: Waiting for a terminator hid the overlay while composing, which made Replace Original feel broken. Overlay translation should follow the same pause-based path as the rest of the app.

**Migration**: Replace Original stays opt-in. Translation starts after the typing pause; the replace shortcut still commits the English result into the field.

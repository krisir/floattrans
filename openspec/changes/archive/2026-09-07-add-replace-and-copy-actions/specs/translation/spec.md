## ADDED Requirements

### Requirement: Replace Original waits for a completed sentence before translating

When Replace Original is on and live translation is enabled, the system SHALL start translation only after the focused text contains a completed Chinese sentence. A sentence is completed when the user types a terminator such as `。` `.` `？` `?` `！` `!` or a newline. Incomplete in-progress Chinese MUST NOT be translated in this mode. When Replace Original is off, existing pause-based live translation is unchanged, including when Copy Translation is on.

#### Scenario: Incomplete sentence is not translated
- **WHEN** Replace Original is on and the user types Chinese that does not yet end with a sentence terminator
- **THEN** no translation overlay appears for that in-progress fragment

#### Scenario: Completed sentence is translated
- **WHEN** Replace Original is on and the user types a Chinese sentence followed by a terminator
- **THEN** the overlay shows the English translation of that completed sentence

#### Scenario: Setting off keeps live pause translation
- **WHEN** Replace Original is off and the user pauses while typing Chinese
- **THEN** the overlay still updates using the existing pause-based translation behavior

### Requirement: Replacement of the focused field happens only on the replace shortcut

When Replace Original is on, a successful translation MUST NOT modify the focused input field by itself. The system SHALL replace the completed source sentence in the focused field with the English translation only after the user presses the configured replace shortcut. Any text before that sentence SHALL be left unchanged. The shortcut MUST work while another application is focused and MUST NOT steal focus from the input field. When Replace Original is off, pressing the replace shortcut MUST NOT change the field.

#### Scenario: Translation does not rewrite the field automatically
- **WHEN** Replace Original is on and a completed Chinese sentence is translated
- **THEN** the focused input field still contains the original Chinese and the overlay shows the English result

#### Scenario: Replace shortcut replaces the completed sentence
- **WHEN** Replace Original is on, a completed sentence has been translated, the field still contains that source sentence, and the user presses the replace shortcut
- **THEN** that source sentence (including its terminator) is replaced with the English translation and earlier text in the field is preserved

#### Scenario: Replace shortcut does nothing without a ready translation
- **WHEN** Replace Original is on and the user presses the replace shortcut but there is no completed sentence with a current translation
- **THEN** the focused field is left unchanged

#### Scenario: Replace shortcut ignored when Replace Original is off
- **WHEN** Replace Original is off and the user presses the replace shortcut
- **THEN** the focused field is left unchanged

#### Scenario: Replace shortcut ignored while translation is paused
- **WHEN** live translation is paused and the user presses the replace shortcut
- **THEN** the focused field is left unchanged

### Requirement: Replace Original does not overwrite stale or unwritable fields

The system SHALL write the translation only if the focused field still contains the same completed source sentence that was translated. If the field cannot be written, or the source sentence is no longer present, the original text SHALL remain and the overlay translation SHALL still be shown.

#### Scenario: User kept typing after translation
- **WHEN** a completed sentence has been translated and the user changes that sentence before pressing the replace shortcut
- **THEN** pressing the shortcut does not write the stale translation into the field

#### Scenario: Field cannot be written
- **WHEN** the user presses the replace shortcut and the focused field rejects the write
- **THEN** the original text remains and the overlay still shows the translation

### Requirement: Copy Translation copies the current English result only on its shortcut

When Copy Translation is on, the system SHALL copy the current English translation to the clipboard only after the user presses the configured copy shortcut. Copying MUST NOT modify the focused input field. The shortcut MUST work while another application is focused and MUST NOT steal focus. When Copy Translation is off, live translation is paused, or there is no current translation, pressing the copy shortcut MUST leave the clipboard unchanged.

#### Scenario: Copy shortcut copies the current translation
- **WHEN** Copy Translation is on, a translation has been accepted for the current sentence, and the user presses the copy shortcut
- **THEN** the clipboard contains that English translation and the focused field is unchanged

#### Scenario: Copy shortcut does nothing without a translation
- **WHEN** Copy Translation is on and the user presses the copy shortcut but there is no current English translation
- **THEN** the clipboard is left unchanged

#### Scenario: Copy shortcut ignored when Copy Translation is off
- **WHEN** Copy Translation is off and the user presses the copy shortcut
- **THEN** the clipboard is left unchanged

#### Scenario: Copy shortcut ignored while translation is paused
- **WHEN** live translation is paused and the user presses the copy shortcut
- **THEN** the clipboard is left unchanged

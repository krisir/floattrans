## MODIFIED Requirements

### Requirement: Replacement of the focused field happens only on the replace shortcut

When Replace Original is on, a successful translation MUST NOT modify the focused input field by itself. The system SHALL replace the current source fragment in the focused field with the English translation only after the user presses the configured replace shortcut. The current source fragment is the exact UTF-16 range captured at the active caret when that translation was requested, including trailing sentence punctuation when that punctuation was part of the translated source. The system MUST pass that range from extraction through to the replace action. The system MUST NOT locate a replacement target by searching another occurrence of the source text, including a backwards string search. Any text outside that captured range SHALL be left unchanged. The shortcut MUST work while another application is focused and MUST NOT steal focus from the input field. When Replace Original is off, pressing the replace shortcut MUST NOT change the field.

#### Scenario: Translation does not rewrite the field automatically
- **WHEN** Replace Original is on and a Chinese fragment is translated
- **THEN** the focused input field still contains the original Chinese and the overlay shows the English result

#### Scenario: Replace shortcut replaces an in-progress fragment
- **WHEN** Replace Original is on, the overlay shows a translation of Chinese that does not yet end with a terminator, the field still contains that fragment at the captured range, and the user presses the replace shortcut
- **THEN** that fragment is replaced with the English translation and earlier text in the field is preserved

#### Scenario: Replace shortcut replaces a completed sentence
- **WHEN** Replace Original is on, a completed sentence including its punctuation has been translated, the field still contains that source sentence at the captured range, and the user presses the replace shortcut
- **THEN** that source sentence including its punctuation is replaced with the English translation (which includes the corresponding English punctuation) and earlier text in the field is preserved

#### Scenario: Repeated sentence replaces the caret occurrence
- **WHEN** a field contains the same Chinese fragment more than once, the caret is in an earlier occurrence, that fragment has a ready translation, and the user presses the replace shortcut
- **THEN** only that earlier captured occurrence changes; later identical text is left unchanged

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

The system SHALL write the translation only if the currently focused field still contains the captured source at the exact UTF-16 range recorded when that translation was requested. If the field cannot be written, the range is out of bounds, or the text at that range is no longer the captured source, the original text SHALL remain and the overlay translation SHALL still be shown. The system MUST NOT fall back to another occurrence of the same string.

#### Scenario: User kept typing after translation
- **WHEN** a fragment has been translated and the user changes the text at the captured range before pressing the replace shortcut
- **THEN** pressing the shortcut does not write the stale translation into the field

#### Scenario: Captured range has changed
- **WHEN** the text at the captured source range no longer equals the source that was translated
- **THEN** pressing the replace shortcut leaves the field unchanged

#### Scenario: Field cannot be written
- **WHEN** the user presses the replace shortcut and the focused field rejects the write
- **THEN** the original text remains and the overlay still shows the translation

## ADDED Requirements

### Requirement: Translation timing chooses when overlay translation starts

While live translation is enabled, the system SHALL start translation according to the selected translation-timing mode:

- **On Pause**: after the configured typing pause, translate the current Chinese fragment even if it has no sentence terminator.
- **Complete Sentence**: translate only after the focused text contains a completed Chinese sentence. A sentence is completed when the user types a terminator such as `。` `.` `？` `?` `！` `!` `；` `;` or a newline. Incomplete in-progress Chinese MUST NOT be translated in this mode.
- **On Shortcut**: do not auto-translate from typing. Translate the current Chinese fragment only after the user presses the configured translate shortcut. The shortcut MUST work while another application is focused and MUST NOT steal focus. Incomplete fragments MAY be translated in this mode.

Replace Original and Copy Translation MUST NOT change which timing mode is used. When live translation is paused, typing and the translate shortcut MUST NOT start a translation.

#### Scenario: On Pause translates an incomplete fragment
- **WHEN** timing is On Pause and the user pauses after typing Chinese that does not end with a terminator
- **THEN** the overlay shows an English translation of that in-progress fragment

#### Scenario: Complete Sentence waits for a terminator
- **WHEN** timing is Complete Sentence and the user types Chinese that does not yet end with a sentence terminator
- **THEN** no translation overlay appears for that in-progress fragment

#### Scenario: Complete Sentence translates after a terminator
- **WHEN** timing is Complete Sentence and the user types a Chinese sentence followed by a terminator
- **THEN** the overlay shows an English translation of that completed sentence

#### Scenario: On Shortcut ignores typing pauses
- **WHEN** timing is On Shortcut and the user types or pauses on Chinese without pressing the translate shortcut
- **THEN** no translation overlay appears from that typing

#### Scenario: On Shortcut translates the current fragment
- **WHEN** timing is On Shortcut, live translation is enabled, the focused field contains Chinese, and the user presses the translate shortcut
- **THEN** the overlay shows an English translation of the current fragment

#### Scenario: Translate shortcut ignored while paused
- **WHEN** live translation is paused and the user presses the translate shortcut
- **THEN** no translation overlay appears

#### Scenario: Replace Original does not force Complete Sentence
- **WHEN** Replace Original is on and timing is On Pause
- **THEN** incomplete Chinese still receives overlay translations after a pause, and the focused field is not rewritten until the replace shortcut is pressed

### Requirement: Sentence-ending punctuation is included in the translated source

When the current fragment ends with sentence punctuation (`。` `？` `！` `.` `?` `!` `；` `;`), that mark SHALL be included in the text sent to translation. The overlay English, the Copy Translation clipboard payload, and the Replace Original source range SHALL all use that same punctuated result. A newline MAY complete a sentence without being included as a translatable character. Incomplete fragments with no trailing punctuation SHALL be translated as-is.

#### Scenario: Period is translated with the sentence
- **WHEN** the current fragment is `我今天会晚一点。` and it is translated
- **THEN** the overlay English includes sentence-final punctuation, Copy Translation copies that full English string, and Replace Original replaces the Chinese including `。`

#### Scenario: Question mark is translated with the sentence
- **WHEN** the current fragment is `你今天来吗？` and it is translated
- **THEN** overlay, copy, and replace all use the translation of that string including `？`

#### Scenario: Incomplete fragment has no terminator to include
- **WHEN** the current fragment is `我今天会晚一点` with no trailing punctuation
- **THEN** translation uses that fragment as-is

#### Scenario: Newline completes without becoming a translated character
- **WHEN** the user ends a Chinese sentence with a newline
- **THEN** the sentence is eligible for Complete Sentence timing, and the newline is not sent to translation as part of the source string

## MODIFIED Requirements

### Requirement: Replacement of the focused field happens only on the replace shortcut

When Replace Original is on, a successful translation MUST NOT modify the focused input field by itself. The system SHALL replace the current source fragment in the focused field with the English translation only after the user presses the configured replace shortcut. The current source fragment is the Chinese text that produced the overlay translation, including trailing sentence punctuation when that punctuation was part of the translated source. Any text before that fragment SHALL be left unchanged. The shortcut MUST work while another application is focused and MUST NOT steal focus from the input field. When Replace Original is off, pressing the replace shortcut MUST NOT change the field.

#### Scenario: Translation does not rewrite the field automatically
- **WHEN** Replace Original is on and a Chinese fragment is translated
- **THEN** the focused input field still contains the original Chinese and the overlay shows the English result

#### Scenario: Replace shortcut replaces an in-progress fragment
- **WHEN** Replace Original is on, the overlay shows a translation of Chinese that does not yet end with a terminator, the field still contains that fragment, and the user presses the replace shortcut
- **THEN** that fragment is replaced with the English translation and earlier text in the field is preserved

#### Scenario: Replace shortcut replaces a completed sentence
- **WHEN** Replace Original is on, a completed sentence including its punctuation has been translated, the field still contains that source sentence, and the user presses the replace shortcut
- **THEN** that source sentence including its punctuation is replaced with the English translation (which includes the corresponding English punctuation) and earlier text in the field is preserved

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

## REMOVED Requirements

### Requirement: Replace Original waits for a completed sentence before translating

**Reason**: Timing is now a separate user setting. Replace Original only commits English into the field; it must not force complete-sentence translation.

**Migration**: Existing installs default to On Pause. Users who still want terminator-gated overlay can choose Complete Sentence. Replace Original remains an independent opt-in action.

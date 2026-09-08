## Purpose

Provides on-device Chinese-to-English translation of the user's current sentence using macOS system translation, from macOS 15 onward, without sending the text to a third-party translation service.

## Requirements

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

### Requirement: Translation timing chooses when overlay translation starts

While live translation is enabled, the system SHALL start translation according to the selected translation-timing mode:

- **On Pause**: after the configured typing pause, translate the current Chinese fragment even if it has no sentence terminator.
- **Complete Sentence**: translate only after the focused text contains a completed Chinese sentence. A sentence is completed when the user types a terminator such as `。` `.` `？` `?` `！` `!` `；` `;` or a newline. Incomplete in-progress Chinese MUST NOT be translated in this mode.
- **On Shortcut**: do not auto-translate from typing. Translate the current Chinese fragment only after the user presses the configured translate shortcut. The shortcut MUST work while another application is focused and MUST NOT steal focus. Incomplete fragments MAY be translated in this mode. When the caret is immediately before or immediately after a sentence terminator, the current fragment SHALL be that completed sentence, including the mark. If a fresh read at that caret would otherwise be empty or lack Chinese, the shortcut MUST still translate that sentence from the field text or the last good snapshot of the same field.

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

#### Scenario: On Shortcut translates with caret after a period
- **WHEN** timing is On Shortcut, the focused field contains `我今天会晚一点。`, the caret is immediately after `。`, and the user presses the translate shortcut
- **THEN** the overlay shows an English translation of `我今天会晚一点。`

#### Scenario: On Shortcut matches caret before the same period
- **WHEN** timing is On Shortcut, the focused field contains `我今天会晚一点。`, the caret is immediately before `。`, and the user presses the translate shortcut
- **THEN** the overlay shows the same English translation as when the caret is immediately after `。`

#### Scenario: On Shortcut recovers when the caret-after-period read is empty
- **WHEN** timing is On Shortcut, the user has just finished a Chinese sentence with a terminator, the caret is after that mark, a fresh Accessibility read at the caret has no Chinese, and the field or the last good snapshot of it still has that sentence
- **THEN** pressing the translate shortcut still shows an English translation of that sentence

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

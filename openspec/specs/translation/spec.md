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

When Replace Original is on, a successful translation MUST NOT modify the focused input field by itself. The system SHALL replace the current source fragment in the focused field with the English translation only after the user presses the configured replace shortcut. The current source fragment is the exact UTF-16 range captured at the active caret when that translation was requested, including trailing sentence punctuation when that punctuation was part of the translated source. The system MUST pass that range from extraction through to the replace action. The system MUST NOT locate a replacement target by searching another occurrence of the source text, including a backwards string search. Any text outside that captured range SHALL be left unchanged. When the captured source was truncated to satisfy a request length limit, Replace Original MUST be unavailable for that translation; overlay display and Copy Translation remain available. The shortcut MUST work while another application is focused and MUST NOT steal focus from the input field. When Replace Original is off, pressing the replace shortcut MUST NOT change the field.

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

#### Scenario: Long source remains display-only
- **WHEN** the caret-resolved source exceeds the request length limit, a truncated fragment is translated, and the user presses the replace shortcut
- **THEN** Copy Translation may copy that result, but the focused field is left unchanged

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

### Requirement: Translation sessions reject obsolete language-pair work

When the selected source or target language changes, local translation work waiting for the previous language pair MUST be cancelled or fail promptly with an unavailable or cancelled error. A session attached for a newly selected pair MUST resume only requests for that same pair. Obsolete requests MUST NOT receive a translation from the new pair or remain blocked until the local-session readiness timeout.

#### Scenario: Direction changes while local session is unavailable
- **WHEN** a request for one language pair is waiting for a local translation session and the user changes direction
- **THEN** the old request finishes without a result promptly and the new direction can establish its own session

#### Scenario: New session does not satisfy old request
- **WHEN** a local session attaches after the user changed to another language pair
- **THEN** only requests for the newly configured pair use that session

### Requirement: Overlay content updates renew the hide duration

When an accepted translation updates an existing overlay, the overlay SHALL remain visible for a full configured hide duration starting from that update. When never-hide is on, the overlay SHALL still not auto-hide.

#### Scenario: Corrected translation renews hide duration
- **WHEN** a visible overlay is updated with a corrected translation before its current hide timer expires
- **THEN** it remains visible for the configured duration after the corrected text appears

### Requirement: Overlay appears on the active input display

The overlay SHALL be presented on the display containing the active focused input when that location is available. It MAY use the main display only when the host application exposes no usable location. Settings preview overlays MAY continue to appear on the main display.

#### Scenario: Input on a secondary display
- **WHEN** the active editable input is on a secondary display and a translation is accepted
- **THEN** the overlay appears on that secondary display

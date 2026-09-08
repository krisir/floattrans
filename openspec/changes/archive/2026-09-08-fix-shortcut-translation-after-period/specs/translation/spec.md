## MODIFIED Requirements

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

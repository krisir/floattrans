## ADDED Requirements

### Requirement: Auto-speak follows translation timing

When 朗读翻译结果 / Read Translations Aloud is on, the system SHALL start auto-speak only for translations accepted while timing is Complete Sentence or On Shortcut. Translations accepted while timing is On Pause MUST still show on the overlay and MUST NOT start speech, including when the paused fragment already ends with a sentence terminator. Turning auto-speak on MUST NOT change the selected timing mode. When auto-speak is off, no translation starts speech.

#### Scenario: On Pause does not speak an in-progress fragment
- **WHEN** auto-speak is on, timing is On Pause, and a pause produces an English overlay for Chinese that does not end with a terminator
- **THEN** the overlay shows that translation and no speech starts for it

#### Scenario: On Pause does not speak a punctuated fragment
- **WHEN** auto-speak is on, timing is On Pause, and a pause produces an English overlay for Chinese that already ends with a terminator
- **THEN** the overlay shows that translation and no speech starts for it

#### Scenario: Complete Sentence speaks the finished sentence
- **WHEN** auto-speak is on, timing is Complete Sentence, and a completed Chinese sentence is translated
- **THEN** the system reads that English translation aloud

#### Scenario: On Shortcut speaks after the translate press
- **WHEN** auto-speak is on, timing is On Shortcut, and the user presses the translate shortcut so an English overlay appears
- **THEN** the system reads that English translation aloud

#### Scenario: Auto-speak off stays silent in every mode
- **WHEN** auto-speak is off and a translation is accepted in On Pause, Complete Sentence, or On Shortcut
- **THEN** no speech starts

#### Scenario: Enabling auto-speak does not change timing
- **WHEN** timing is On Pause and the user turns auto-speak on
- **THEN** timing remains On Pause

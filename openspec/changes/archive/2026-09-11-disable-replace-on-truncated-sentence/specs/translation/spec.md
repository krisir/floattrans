## MODIFIED Requirements

### Requirement: Replacement of the focused field happens only on the replace shortcut

When Replace Original is on, a successful translation MUST NOT modify the focused input field by itself. The system SHALL replace the current source fragment in the focused field with the English translation only after the user presses the configured replace shortcut. The current source fragment is the Chinese text that produced the overlay translation, including trailing sentence punctuation when that punctuation was part of the translated source. Any text before that fragment SHALL be left unchanged. When the captured source was truncated to satisfy a request length limit, Replace Original MUST be unavailable for that translation; overlay display and Copy Translation remain available. The shortcut MUST work while another application is focused and MUST NOT steal focus from the input field. When Replace Original is off, pressing the replace shortcut MUST NOT change the field.

#### Scenario: Translation does not rewrite the field automatically
- **WHEN** Replace Original is on and a Chinese fragment is translated
- **THEN** the focused input field still contains the original Chinese and the overlay shows the English result

#### Scenario: Replace shortcut replaces an in-progress fragment
- **WHEN** Replace Original is on, the overlay shows a translation of Chinese that does not yet end with a terminator, the field still contains that fragment, and the user presses the replace shortcut
- **THEN** that fragment is replaced with the English translation and earlier text in the field is preserved

#### Scenario: Replace shortcut replaces a completed sentence
- **WHEN** Replace Original is on, a completed sentence including its punctuation has been translated, the field still contains that source sentence, and the user presses the replace shortcut
- **THEN** that source sentence including its punctuation is replaced with the English translation (which includes the corresponding English punctuation) and earlier text in the field is preserved

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

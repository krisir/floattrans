## ADDED Requirements

### Requirement: Speech section explains when auto-speak plays

The Translation-page Speech section SHALL keep the 朗读翻译结果 / Read Translations Aloud switch in every timing mode. When auto-speak is on and translation timing is On Pause, the section SHALL show a hint that speech plays only for Complete Sentence and On Shortcut. When auto-speak is off, or timing is Complete Sentence or On Shortcut, that hint SHALL NOT be shown. All visible labels SHALL follow the selected interface language.

#### Scenario: Hint appears for auto-speak during On Pause
- **WHEN** auto-speak is on, timing is On Pause, and the user views the Translation page
- **THEN** a hint under the auto-speak switch explains that speech plays only in Complete Sentence or On Shortcut

#### Scenario: Hint hidden when auto-speak is off
- **WHEN** auto-speak is off and the user views the Translation page
- **THEN** the Speech section does not show that timing hint

#### Scenario: Hint hidden for Complete Sentence
- **WHEN** auto-speak is on, timing is Complete Sentence, and the user views the Translation page
- **THEN** the Speech section does not show that timing hint

#### Scenario: Hint hidden for On Shortcut
- **WHEN** auto-speak is on, timing is On Shortcut, and the user views the Translation page
- **THEN** the Speech section does not show that timing hint

#### Scenario: Hint follows Chinese interface
- **WHEN** the interface language is 中文, auto-speak is on, timing is On Pause, and the user views the Translation page
- **THEN** the hint is shown in Simplified Chinese

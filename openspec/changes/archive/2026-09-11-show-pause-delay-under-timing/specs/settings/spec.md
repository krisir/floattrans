## MODIFIED Requirements

### Requirement: Translation page includes translation timing

The 翻译 page SHALL include a 翻译时机 / Translation Timing control with exactly three options: 超时翻译 / On Pause, 完整句子翻译 / Complete Sentence, and 快捷键触发翻译 / On Shortcut. All visible labels SHALL follow the selected interface language. Changing the mode SHALL take effect without requiring an app restart. The 停顿后翻译 / Translate After Pause control SHALL appear immediately below Translation Timing and SHALL be shown only when On Pause is selected. When On Shortcut is selected, the page SHALL show a translate-shortcut control immediately below Translation Timing; that control MUST NOT be shown in the other modes.

#### Scenario: Timing control is visible
- **WHEN** the user views the Translation page
- **THEN** the page shows Translation Timing with the three options and the currently selected mode

#### Scenario: Timing labels follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Translation page
- **THEN** the timing label and options are shown in Simplified Chinese

#### Scenario: Timing labels follow English interface
- **WHEN** the interface language is English and the user views the Translation page
- **THEN** the timing label and options are shown in English

#### Scenario: Pause delay sits under timing in On Pause
- **WHEN** the user selects On Pause
- **THEN** 停顿后翻译 / Translate After Pause is shown immediately below Translation Timing

#### Scenario: Pause delay hidden for Complete Sentence
- **WHEN** the user selects Complete Sentence
- **THEN** the pause-delay control is not shown

#### Scenario: Pause delay hidden for On Shortcut
- **WHEN** the user selects On Shortcut
- **THEN** the pause-delay control is not shown and the translate-shortcut control is shown immediately below Translation Timing

#### Scenario: Hidden pause delay is kept
- **WHEN** the user changes the pause delay, switches to Complete Sentence or On Shortcut, then switches back to On Pause
- **THEN** the previously stored delay is shown again without being reset

#### Scenario: Shortcut recorder appears for On Shortcut
- **WHEN** the user selects On Shortcut
- **THEN** a translate-shortcut control is shown and recording a combination uses that combination for subsequent translate presses

#### Scenario: Shortcut recorder hidden for other modes
- **WHEN** the user selects On Pause or Complete Sentence
- **THEN** the translate-shortcut control is not shown

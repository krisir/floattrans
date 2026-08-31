## Purpose

Defines the 浮译 menu bar extra: which items it shows, how those labels follow the selected interface language, and which informational lines are intentionally omitted.

## ADDED Requirements

### Requirement: Menu bar shows pause, settings, and quit

The menu bar extra SHALL offer controls to pause or resume live translation, open Settings, and quit the app. It SHALL NOT show a translation source → target caption, and SHALL NOT offer an About menu item (About lives in Settings).

#### Scenario: Menu contents
- **WHEN** the user opens the menu bar extra
- **THEN** the menu shows pause/resume, Settings, and Quit, and does not show a `中文 → English` (or similar) direction line or an About item

#### Scenario: Opening settings
- **WHEN** the user chooses Settings from the menu bar
- **THEN** the Settings window opens (or is brought to the front)

### Requirement: Menu bar labels follow the interface language

Menu bar item labels SHALL use the selected interface language (Simplified Chinese or English), matching the Settings interface-language preference. Changing the language in Settings SHALL update subsequent menu bar labels without requiring an app restart.

#### Scenario: Chinese labels
- **WHEN** the interface language is 中文 and the user opens the menu bar
- **THEN** pause/resume, Settings, and Quit labels are shown in Simplified Chinese

#### Scenario: English labels
- **WHEN** the interface language is English and the user opens the menu bar
- **THEN** pause/resume, Settings, and Quit labels are shown in English

#### Scenario: Language change updates the menu
- **WHEN** the user switches the interface language in Settings and then reopens the menu bar
- **THEN** the menu labels reflect the newly selected language

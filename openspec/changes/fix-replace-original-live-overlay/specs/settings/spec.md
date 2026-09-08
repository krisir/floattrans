## ADDED Requirements

### Requirement: Replace Original hint describes overlay then shortcut

The Replace Original control SHALL include hint text that the overlay updates after a typing pause and that the replace shortcut writes the English result into the field. The hint MUST NOT tell the user that they have to finish a sentence or type a terminator before the overlay appears.

#### Scenario: Chinese hint matches live overlay
- **WHEN** the interface language is 中文 and Replace Original is shown
- **THEN** the hint says the overlay appears after a pause and the shortcut replaces the field, without requiring a completed sentence first

#### Scenario: English hint matches live overlay
- **WHEN** the interface language is English and Replace Original is shown
- **THEN** the hint says the overlay appears after a pause and the shortcut replaces the field, without requiring a completed sentence first

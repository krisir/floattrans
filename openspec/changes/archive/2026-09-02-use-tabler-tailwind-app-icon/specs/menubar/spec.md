## ADDED Requirements

### Requirement: Menu bar status item uses Tabler brand-tailwind mark

The menu bar extra status item SHALL display a template rendering of the Tabler Icons outline `brand-tailwind` mark. The status item icon SHALL remain the same whether live translation is paused or resumed; pause and resume SHALL continue to be controlled only through the menu item labels.

#### Scenario: Status item shows brand-tailwind while running
- **WHEN** live translation is enabled and the menu bar extra is visible
- **THEN** the status item shows the brand-tailwind template mark (not the SF Symbol `waveform`)

#### Scenario: Status item stays brand-tailwind when paused
- **WHEN** the user pauses live translation
- **THEN** the status item continues to show the same brand-tailwind template mark and does not switch to a pause symbol

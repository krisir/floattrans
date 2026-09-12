## ADDED Requirements

### Requirement: Overlay appears on the active input display

The overlay SHALL be presented on the display containing the active focused input when that location is available. It MAY use the main display only when the host application exposes no usable location. Settings preview overlays MAY continue to appear on the main display.

#### Scenario: Input on a secondary display
- **WHEN** the active editable input is on a secondary display and a translation is accepted
- **THEN** the overlay appears on that secondary display

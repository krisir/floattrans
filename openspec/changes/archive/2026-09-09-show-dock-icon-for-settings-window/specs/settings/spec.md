## ADDED Requirements

### Requirement: Settings window stays reachable after switching apps

While the Settings window exists (visible or miniaturized), the running app SHALL be present in the Dock and the Cmd+Tab application switcher so the user can return to Settings without using the menu bar. Closing Settings SHALL remove that presence when no Welcome window remains. Choosing Settings from the menu bar SHALL still open Settings or bring the existing window to the front.

#### Scenario: Settings is reachable from the Dock
- **WHEN** the user opens Settings, switches to another application, and clicks the FloatTrans Dock tile
- **THEN** the Settings window becomes key and ordered front

#### Scenario: Settings is reachable from Cmd+Tab
- **WHEN** the user opens Settings, switches to another application, and selects FloatTrans in Cmd+Tab
- **THEN** the Settings window becomes key and ordered front

#### Scenario: Closing Settings restores menu-bar-only presence
- **WHEN** the user closes the Settings window and Welcome is not open
- **THEN** FloatTrans leaves the Dock and Cmd+Tab, and the menu bar extra remains available

#### Scenario: Menu bar still opens or focuses Settings
- **WHEN** Settings is already open and the user chooses Settings from the menu bar extra
- **THEN** the existing Settings window is brought to the front

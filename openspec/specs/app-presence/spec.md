## Purpose

Defines when the running 浮译 process appears in the macOS Dock and the Cmd+Tab application switcher, so chrome windows stay reachable without making the app a persistent Dock app.

## Requirements

### Requirement: App is a menu-bar agent by default

At launch, and whenever no Settings or Welcome window exists, the app SHALL NOT appear in the Dock and SHALL NOT appear in the Cmd+Tab application switcher. The menu bar extra remains the standing control surface.

#### Scenario: Launch with no chrome windows
- **WHEN** the app finishes launching and the user has already completed onboarding
- **THEN** the Dock does not show a FloatTrans tile and Cmd+Tab does not include FloatTrans

#### Scenario: Overlay running without Settings
- **WHEN** live translation is enabled and an overlay is visible, and Settings and Welcome are both closed
- **THEN** the Dock still does not show a FloatTrans tile

### Requirement: Chrome windows make the app switchable

While a Settings window or a Welcome window exists — including when that window is miniaturized — the app SHALL appear in the Dock and in the Cmd+Tab application switcher. Switching to another application SHALL NOT remove that presence for as long as a chrome window still exists.

#### Scenario: Opening Settings adds Dock presence
- **WHEN** the user opens Settings from the menu bar
- **THEN** a FloatTrans tile appears in the Dock and FloatTrans appears in Cmd+Tab

#### Scenario: Switching away keeps presence
- **WHEN** Settings is open and the user activates another application
- **THEN** the FloatTrans Dock tile remains and Cmd+Tab still includes FloatTrans

#### Scenario: Miniaturized Settings keeps presence
- **WHEN** the user miniaturizes the Settings window
- **THEN** the FloatTrans Dock tile remains so the window can be restored

#### Scenario: Welcome during onboarding is chrome
- **WHEN** first-run Welcome is on screen
- **THEN** a FloatTrans tile appears in the Dock and Cmd+Tab includes FloatTrans

### Requirement: Overlay and translation host never grant presence

Showing, hiding, or updating the translation overlay, and keeping the hidden translation-host panel alive, SHALL NOT by themselves make the app appear in the Dock or Cmd+Tab.

#### Scenario: Overlay alone
- **WHEN** an overlay panel is shown and no Settings or Welcome window exists
- **THEN** the app does not appear in the Dock or Cmd+Tab

#### Scenario: Overlay while Settings is open
- **WHEN** Settings is open and an overlay is also shown
- **THEN** Dock and Cmd+Tab presence continue to follow the Settings window, not the overlay

### Requirement: Dock interaction focuses chrome

Clicking the FloatTrans Dock tile, or otherwise asking the app to reopen, SHALL bring an existing chrome window to the front. If Settings exists, it takes priority; otherwise Welcome is focused. Miniaturized windows SHALL be deminiaturized.

#### Scenario: Dock click focuses Settings
- **WHEN** Settings is open but behind another app and the user clicks the FloatTrans Dock tile
- **THEN** the Settings window becomes key and ordered front

#### Scenario: Dock click restores a miniaturized window
- **WHEN** Settings is miniaturized and the user clicks the FloatTrans Dock tile
- **THEN** the Settings window is deminiaturized and ordered front

### Requirement: Closing the last chrome window restores agent presence

When the last Settings or Welcome window is closed, the app SHALL leave the Dock and the Cmd+Tab switcher. If another chrome window is still open, presence SHALL remain.

#### Scenario: Closing Settings with no Welcome
- **WHEN** the user closes Settings and Welcome is not open
- **THEN** the FloatTrans Dock tile disappears and Cmd+Tab no longer includes FloatTrans

#### Scenario: Closing Settings while Welcome remains
- **WHEN** Welcome is still open and the user closes Settings
- **THEN** the FloatTrans Dock tile remains

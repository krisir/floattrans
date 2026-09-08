## ADDED Requirements

### Requirement: About tab can check GitHub for updates

The Settings About tab SHALL include a 检查更新 / Check for Updates control. Activating it SHALL compare the running app's marketing version with the latest published GitHub release for `krisir/floattrans`. The check SHALL run only when the user activates the control; the app SHALL NOT poll GitHub in the background or download an installer. While a check is in progress, the control SHALL be disabled. Button label and status text SHALL follow the selected interface language.

#### Scenario: About shows the check control
- **WHEN** the user selects the About tab
- **THEN** the page shows a 检查更新 button when the interface language is 中文, or Check for Updates when it is English

#### Scenario: Newer release opens GitHub
- **WHEN** the user activates Check for Updates and GitHub's latest published release has a higher version than the running app
- **THEN** the default browser opens that release's GitHub page and the About tab does not claim the app is up to date

#### Scenario: Already up to date
- **WHEN** the user activates Check for Updates and the latest published GitHub release is the same version as the running app, or is not newer
- **THEN** the About tab shows localized status that the app is up to date and the browser does not open

#### Scenario: Check fails
- **WHEN** the user activates Check for Updates and the latest-release lookup fails (network error, unexpected response, or no published release)
- **THEN** the About tab shows localized status that the check failed and the browser does not open

#### Scenario: Check is in progress
- **WHEN** a check for updates is in progress
- **THEN** the Check for Updates control cannot be activated again until the check finishes

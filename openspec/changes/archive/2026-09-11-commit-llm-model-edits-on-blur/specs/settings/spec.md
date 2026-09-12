## ADDED Requirements

### Requirement: Model edits commit without disrupting live translation per keystroke

While editing a language-model configuration, intermediate text changes SHALL remain a local draft. The app MUST NOT reconfigure the active translation backend, cancel an active translation, hide an existing overlay, or persist an API key for every typed character. The app SHALL apply and persist the edited model when the user commits the edit through the editor's commit boundary (explicit save or focus loss). All visible commit controls and feedback SHALL follow the selected interface language.

#### Scenario: Typing an API key leaves current translation intact
- **WHEN** a user types into a language-model API-key field while an overlay is visible
- **THEN** the current overlay remains visible and the active translation is not cancelled for each character

#### Scenario: Committed model edit takes effect
- **WHEN** a user commits a changed language-model configuration
- **THEN** the configuration is persisted, its API key is stored in Keychain when applicable, and subsequent translations use the committed configuration

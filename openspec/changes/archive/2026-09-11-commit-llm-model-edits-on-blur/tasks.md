## 1. Commit boundary

- [x] 1.1 Keep model-editor changes in a local draft until explicit save or focus loss; add discard behavior.
- [x] 1.2 Persist API keys and call `applyTranslationSettings()` once per committed edit, not per typed character.
- [x] 1.3 Add tests verifying intermediate draft edits do not reconfigure runtime or write Keychain, while committed edits do.

## 2. Verification

- [x] 2.1 Run the focused settings tests and the full Swift test suite.
- [x] 2.2 Manually verify typing an API key does not hide the current overlay or cancel an in-flight translation.

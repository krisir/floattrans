## 1. Drop the completeness gate

- [ ] 1.1 Stop setting `InputCoordinator.requireCompletedSentence` from Replace Original in `AppState` init and `setReplaceOriginal`
- [ ] 1.2 Remove or unused-path `requireCompletedSentence` in `InputCoordinator.handle` so pause debounce always extracts and translates Chinese fragments
- [ ] 1.3 Confirm `FieldReplacement.evaluate` still captures an in-progress fragment (no terminator) and a completed sentence (with terminator) for the pending replace payload

## 2. Settings copy

- [ ] 2.1 Update `L10n.replaceOriginalHint` in Chinese and English so it describes overlay-after-pause and shortcut-to-replace, with no “finish the sentence first” wording
- [ ] 2.2 Update any Settings-store tests that assert the old hint strings

## 3. Tests

- [ ] 3.1 Add or adjust tests so an incomplete Chinese snapshot is extracted and considered translatable even when Replace Original would previously have required a terminator
- [ ] 3.2 Keep coverage that replace rewrites the full current fragment, including the terminator when one is present, and skips stale or missing source
- [ ] 3.3 Run the LiveEnglish unit tests and confirm they pass

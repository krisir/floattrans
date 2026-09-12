## 1. Range-bearing replace

- [x] 1.1 Introduce a range-bearing extracted-source value that keeps the caret-resolved UTF-16 range.
- [x] 1.2 Pass that value through `InputCoordinator`, pending actions, and `AppState` instead of reconstructing identity with backwards string searches.
- [x] 1.3 Replace only when the current focused field contains the captured source at its captured range; fail closed on range or content mismatch.
- [x] 1.4 Add tests for duplicate source text at different caret positions and for changed text at the captured range.

## 2. Verification

- [x] 2.1 Run the focused replace tests and the full Swift test suite.
- [x] 2.2 Manually verify a repeated sentence only replaces the occurrence at the active caret.

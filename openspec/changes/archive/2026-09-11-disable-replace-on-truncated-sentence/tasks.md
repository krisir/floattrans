## 1. Truncation disables replace

- [x] 1.1 Record truncation state when extraction keeps only a suffix to meet the request length limit.
- [x] 1.2 Drop the replacement payload for truncated sources; keep overlay display and Copy Translation.
- [x] 1.3 Add tests that an over-300-character fragment can translate but the replace shortcut leaves the field unchanged.

## 2. Verification

- [x] 2.1 Run the focused extractor/replace tests and the full Swift test suite.
- [x] 2.2 Manually verify a long sentence never partially rewrites the field.

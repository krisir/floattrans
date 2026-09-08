## 1. Extractor

- [x] 1.1 Map `selectedRange` with UTF-16 `String.Index` on the untrimmed field instead of mixing UTF-16 offsets with `Array(String)` indices
- [x] 1.2 When the caret is immediately after a terminator, extract that completed sentence (punctuation included; newline still omitted) rather than an empty following slice
- [x] 1.3 If the slice at the caret is empty or has no Chinese and a previous sentence exists, use that previous sentence

## 2. Shortcut snapshot

- [x] 2.1 Keep last-good non-empty focused-field text; do not overwrite it with an empty Accessibility value
- [x] 2.2 On `snapshotNow`, if the live extract has no Chinese, recover via AXStringForRange when possible, otherwise last-good text with the caret after the last terminator
- [x] 2.3 Clear last-good text on focus change so a previous field is not reused

## 3. Tests

- [x] 3.1 Assert extract is identical for caret immediately before vs after `。` / `.` / `？` on `我今天会晚一点。` (and the other marks)
- [x] 3.2 Assert `translateNow` still emits that sentence when the live snapshot text is empty but last-good text has it
- [x] 3.3 Run the LiveEnglish unit tests and confirm they pass

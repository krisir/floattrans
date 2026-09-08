## 1. Glyphs and defaults

- [x] 1.1 Map ANSI `[` (`0x21`) and `]` (`0x1E`) plus remaining punctuation/digit keyCodes in `ReplaceShortcut.glyph(for:)` so labels never show `Key 30` for those keys
- [x] 1.2 Add Option-Shift-`[` and Option-Shift-`]` constants and use them as replace/copy load fallbacks instead of Control-Shift-Return / Control-Shift-C
- [x] 1.3 Keep `displayString` as `⌥⇧[` / `⌥⇧]` when Shift is included (not `{` / `}`)

## 2. Tests

- [x] 2.1 Assert default and displayed replace/copy shortcuts, and that stored keyCode pairs are not overwritten
- [x] 2.2 Run the LiveEnglish unit tests and confirm they pass

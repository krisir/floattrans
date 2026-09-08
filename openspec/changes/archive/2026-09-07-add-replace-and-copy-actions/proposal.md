## Why

FloatTrans currently shows English only in a floating overlay. People composing in another app still have to copy the overlay by hand, or want the field itself rewritten. Optional shortcut actions let them replace the original sentence or copy the translation when they are ready, without changing the default overlay-only workflow.

## What Changes

- Add a **替换原文 / Replace Original** setting on the Translation page, off by default.
- When Replace Original is on, do **not** start translation until the user finishes a sentence (for example `。` `.` `？` `?` `！` `!` or a newline). Incomplete Chinese MUST NOT be translated in this mode.
- After a successful translation in this mode, show the overlay as today. Do **not** write into the input field automatically.
- Add a global replace shortcut (default **⌃⇧↩**, configurable). Pressing it replaces the completed source sentence in the focused field with the English result, leaving earlier text unchanged.
- Add a **复制译文 / Copy Translation** setting on the Translation page, off by default, with its own global shortcut (default **⌃⇧C**, configurable).
- When Copy Translation is on, pressing its shortcut copies the current English translation to the clipboard. It MUST NOT change the focused field.
- Overlay, speech, and pause-based live translation stay as they are when both settings are off. Each shortcut MUST do nothing while its setting is off or live translation is paused.
- If the focused field cannot be written, or the source sentence is no longer in the field, keep the original text and still show the overlay. If there is no current translation, copy MUST leave the clipboard unchanged.

## Capabilities

### New Capabilities

- None. Sentence completion, field replace, clipboard copy, and translation stay under the existing `translation` capability.

### Modified Capabilities

- `settings`: Translation page gains persisted Replace Original and Copy Translation toggles (both default off) and two persisted shortcuts (replace: Control-Shift-Return; copy: Control-Shift-C), localized in both interface languages, with existing-install defaults that do not change other settings.
- `translation`: When Replace Original is on, translation starts only after a completed sentence and the field is rewritten only on the replace shortcut. When Copy Translation is on, the copy shortcut puts the current English translation on the clipboard.

## Impact

- `Sources/LiveEnglish/Settings.swift` / `SettingsUI.swift` / `L10n.swift` — toggles, shortcuts, persistence, copy
- `Sources/LiveEnglish/Models.swift` — complete-sentence detection for Replace Original
- `Sources/LiveEnglish/Input.swift` — gate extraction until a terminator; Accessibility write-back for replace
- `Sources/LiveEnglish/App.swift` — two global hotkeys; pending translation payload; clipboard write
- Tests for sentence completion, replace-range construction, stale-write guards, shortcut gating, clipboard copy, and settings defaults
- Product copy (`README.md`, landing page) if it currently describes overlay-only output
- No new third-party dependencies

## Context

See `proposal.md` for motivation. `ReplaceShortcut.displayString` prefixes Carbon modifier glyphs, then `glyph(for:)` maps a few special keys and A–Z / some digits. Unknown keyCodes become `Key \(keyCode)`. ANSI `]` is `0x1E` (decimal 30); ANSI `[` is `0x21`. Defaults today are Control-Shift-Return and Control-Shift-C.

## Goals / Non-Goals

**Goals:**
- Map `[` and `]` (and the rest of the usual ANSI punctuation row) so shortcut chips never show `Key 30` for those keys.
- Ship Option-Shift-`[` / Option-Shift-`]` as replace/copy fallbacks.

**Non-Goals:**
- No layout-aware glyphs for non-ANSI keyboards beyond hardware keyCode maps.
- No migrating already-stored Control-Shift-Return / Control-Shift-C values.
- No change to translate-on-shortcut default or hotkey registration mechanics.

## Decisions

### D1: Unshifted ANSI character, modifiers shown separately

Display `[` / `]` even when Shift is down. The chip is `⌥⇧[`, not `⌥⇧{`. Shortcuts name the key, not the typed character.

Alternatives considered: showing `{` when Shift is held matches typing but not macOS shortcut chrome (e.g. Safari’s ⌘[).

### D2: Hardware keyCodes `0x21` and `0x1E`

Use `kVK_ANSI_LeftBracket` (`0x21`) for `[` and `kVK_ANSI_RightBracket` (`0x1E`) for `]`. Decimal 30 is `]`, which is why the current fallback reads `Key 30` for that key.

Also map the adjacent punctuation/digit keyCodes that today fall through (`-` `=` `\` `;` `'` `,` `.` `/` and remaining digits) so the same class of bug does not recur.

### D3: New defaults only when keys are missing

`ReplaceShortcut.optionShiftLeftBracket` and `.optionShiftRightBracket` become the load fallbacks. If UserDefaults already has replace/copy keyCode+modifier pairs, leave them.

## Risks / Trade-offs

- [Option-Shift-bracket may collide with system or IME shortcuts] → Mitigation: still user-recordable; user asked for these defaults.
- [Non-US keyboards may label the same keyCodes differently] → Mitigation: display the ANSI character for that keyCode; recording still binds the hardware key.

## Migration Plan

1. Ship glyph maps and new fallbacks.
2. Existing stored shortcuts keep working with better labels.
3. Rollback is restoring Control-Shift-Return / Control-Shift-C fallbacks and the old glyph table.

## Open Questions

None.

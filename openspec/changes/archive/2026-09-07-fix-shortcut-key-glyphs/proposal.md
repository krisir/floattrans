## Why

Shortcut chips currently fall back to `Key 30` for keys like `[` / `]`, so Option-Shift-bracket combinations are unreadable. Those same keys are the desired defaults for replace and copy, so the label and the shipped defaults need to match.

## What Changes

- Show ANSI punctuation keys as their unshifted characters in shortcut labels. Option-Shift-`[` MUST display as `⌥⇧[` (not `Key 30` or `{`).
- **BREAKING (defaults)**: Replace Original defaults to Option-Shift-`[` and Copy Translation defaults to Option-Shift-`]`, replacing Control-Shift-Return and Control-Shift-C.
- Fresh installs and missing shortcut keys use the new defaults. Already-stored custom or previous defaults stay as recorded.
- Translate-on-shortcut default (Control-Shift-T) is unchanged.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `settings`: Shortcut display for bracket keys, and new replace/copy default combinations plus persistence fallbacks.

## Impact

- `ReplaceShortcut.glyph(for:)` and default constants in Settings; SettingsStore tests for display strings and missing-key defaults.
- Carbon hotkey registration already uses keyCode + modifiers; no new APIs.

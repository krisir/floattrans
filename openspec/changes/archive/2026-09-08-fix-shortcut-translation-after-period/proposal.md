## Why

On Shortcut, pressing translate with the caret after a sentence terminator (`。` `.` `？` and the rest) often produces no overlay, while the same sentence translates if the caret is still before that mark. Pause and Complete Sentence already see the sentence when the mark is typed; the shortcut re-reads the field later and misses it.

## What Changes

- On Shortcut, a caret immediately after a sentence terminator MUST translate that completed sentence, including the mark — same result as a caret immediately before the mark.
- If a fresh Accessibility read has no Chinese fragment at that caret (empty value, empty slice after the terminator, or non-Chinese punctuation-only slice), the shortcut MUST still use the sentence that terminator closed, from the current field text or the last good snapshot of that field.
- Incomplete fragments with no terminator remain translatable on shortcut when the caret is inside them.
- Overlay, Replace Original, Copy Translation, and timing modes other than the shared extract behavior stay as they are. Complete Sentence still only auto-starts when a terminator is at the caret.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: On Shortcut treats a caret after a sentence terminator as belonging to that sentence, not as an empty next fragment.

## Impact

- `SentenceExtractor.extract` caret mapping, `AccessibilityMonitor.snapshotNow` / last-good field text, `InputCoordinator.translateNow`, and extractor/shortcut unit tests.
- Settings UI and hotkey registration are unchanged.

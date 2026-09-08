## Why

Replace Original currently hijacks *when* translation starts (wait for a period), but people want to choose that separately: after a pause, after a completed sentence, or only when they press a shortcut. One timing control covers composing, finishing a sentence, and on-demand translation without tying those choices to replace/copy.

## What Changes

- Add a Translation Timing / 翻译时机 setting on the Translation page with three modes: timeout (pause), complete sentence, and shortcut.
- **Timeout**: translate the current Chinese fragment after the existing translation-speed pause. This is the default.
- **Complete sentence**: translate only after the user types a terminator (`。` `.` `？` `?` `！` `!` newline, and the existing semicolon set).
- **Shortcut**: do not auto-translate; translate the current fragment only when the user presses a dedicated, configurable translate shortcut (default Control-Shift-T). Do not use Control-Option-Return as a default; that combination is commonly taken.
- **BREAKING (timing vs Replace Original)**: Replace Original MUST NOT force complete-sentence timing. It only means “press the replace shortcut to write English into the field.” Overlay timing follows the new setting in all cases, including when Replace Original is on.
- Translation speed continues to apply only in timeout mode. Complete-sentence and shortcut modes translate when their trigger fires, without waiting for that pause.
- Include sentence-ending punctuation (`。` `？` `！` `.` `?` `!` `；` `;`) in the text sent to translation, so the overlay, Copy Translation, and Replace Original all carry the matching English punctuation. A newline may still end a sentence without being sent as a translatable character.
- Existing installs without a stored timing value default to timeout. Stored Replace Original and copy/replace shortcuts are left unchanged.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `settings`: Translation page control, labels, persistence, defaults, and hint copy for translation timing and the translate shortcut.
- `translation`: When translation starts in each of the three modes; sentence-ending punctuation is part of the translated source; Replace Original no longer gates on a terminator.

## Impact

- Settings model/UI/`L10n`, `InputCoordinator` completeness/debounce gating, `SentenceExtractor` (keep trailing punctuation), `AppState` hotkeys (third Carbon hotkey for translate), and unit tests for defaults plus extract/replace/copy of punctuated sentences.
- Overlay chrome stays as it is. Copy still copies the current overlay result. Replace still writes only on its own shortcut after a translation exists.

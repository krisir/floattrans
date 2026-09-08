## Context

See `proposal.md` for motivation. Today `AppState` sets `InputCoordinator.requireCompletedSentence` from `settings.replaceOriginal`, so turning on replace also hides the overlay until a terminator. `SentenceExtractor.extract` drops trailing `。` / `？` / `！` before translation, so overlay and copy miss English punctuation. Debounce delay comes from `translationSpeed`. Carbon hotkeys exist only for replace and copy.

## Goals / Non-Goals

**Goals:**
- Drive auto-translation from a single `TranslationTiming` setting, not from Replace Original.
- Register a third hotkey only while timing is On Shortcut and live translation is enabled.
- Keep replace/copy actions independent of timing.
- Keep trailing sentence punctuation on the extracted source so overlay, copy, and replace share one punctuated result.

**Non-Goals:**
- No combining translate + replace onto one key.
- No OS-level shortcut conflict detector.
- No keystroke-injection fallback for replace writes.
- No sending newline into the translation engine as source text.

## Decisions

### D1: Enum `TranslationTiming` with three persisted raw values

`pause` (超时翻译), `completeSentence` (完整句子翻译), `shortcut` (快捷键触发翻译). Store the raw string in UserDefaults. Missing key → `pause`. Do not infer timing from `replaceOriginal`.

Alternatives considered: keeping completeness tied to Replace Original was rejected. Two booleans (auto vs wait-for-period) cannot express shortcut-only.

### D2: Pipeline switch in `InputCoordinator`

Replace `requireCompletedSentence` with `timing`:

- `pause`: current debounce, then extract/translate if Chinese.
- `completeSentence`: if `isComplete`, extract/translate immediately; otherwise ignore the snapshot (no speed debounce).
- `shortcut`: ignore snapshot-driven translate (still track the latest snapshot for the hotkey). Cancel debounce so pauses do not fire.

On Shortcut, the translate hotkey reads the latest focused snapshot (refresh AX if needed), extracts the current fragment, and runs the same `translate` path as debounce.

Alternatives considered: using the replace shortcut as the translate trigger was rejected; replace still means write-to-field after a result exists. Translating on every keystroke in pause mode was rejected; keep speed-based debounce.

### D3: Third Carbon hotkey, default ⌃⇧T

Add `TranslationHotKeyAction.translate`. Register it only when enabled and timing is `shortcut`. Default Control-Shift-T. Do not default to Control-Option-Return. Settings shows the recorder only in shortcut mode; the stored shortcut still persists if the user switches away and back.

Alternatives considered: always registering the translate hotkey in pause/complete modes would surprise people who only wanted auto overlay.

### D4: Speed only feeds On Pause debounce

`translationSpeed` remains 300/450/700 ms and only sets `InputDebouncer.delay` when timing is `pause`. Complete Sentence translates on a snapshot that is already complete (terminator at the caret) without waiting that pause; a snapshot that is not complete is ignored. On Shortcut bypasses the debouncer and translates immediately from the hotkey.

### D5: Extract keeps trailing sentence punctuation

Today `SentenceExtractor.extract` moves the caret before a terminator and returns the sentence without it, then `FieldReplacement.evaluate` re-attaches the next punctuation character for replace only. Translation therefore omits `。` / `？` / `！`, so overlay and copy lack English punctuation and replace has to stitch ranges.

Change extract so that if the fragment’s end (or the caret) is on sentence punctuation (`。？！.?!；;`), that character is included in the returned string. Newline remains a completeness boundary but is not appended to the extract. Pass that exact string to translate. Overlay, copy, and replace all consume that generation’s English. For replace, match the extracted source exactly; do not append a second terminator if the source already ends with punctuation.

Alternatives considered: translating without punctuation and appending `.` after the fact was rejected; the engine should see the mark. Re-attaching punctuation only on replace leaves copy/overlay incomplete.

### D6: Replace payload is the extracted fragment

Whenever a translation is requested (any mode), if Replace Original is on, store the extracted source (punctuation included when present) as the replace range. Incomplete fragments still have terminator length 0.

## Risks / Trade-offs

- [Users who relied on Replace Original implying complete-sentence] → Mitigation: they can pick Complete Sentence; default On Pause matches composing. Mentioned as BREAKING in the proposal.
- [On Shortcut with no current snapshot] → Mitigation: refresh AX on hotkey; no-op if the field has no Chinese.
- [Hotkey conflicts for ⌃⇧T] → Mitigation: user-recordable; unregistered except in shortcut mode.
- [Complete Sentence fires on the AX snapshot that includes the terminator] → Mitigation: IME commit is already reflected in that snapshot; no extra speed wait.
- [English punctuation may not match the Chinese mark one-to-one] → Mitigation: include the mark in the source and accept the engine’s English punctuation; do not append a second period after the result.

## Migration Plan

1. Ship timing default `pause` and translate shortcut ⌃⇧T when keys are missing.
2. Stop setting completeness from `replaceOriginal`. Stored replace/copy values stay.
3. Rollback is restoring `requireCompletedSentence = replaceOriginal` and removing the timing control; unused UserDefaults keys can remain.

## Open Questions

None.

## Context

See `proposal.md` for motivation. Today `AppState` sets `InputCoordinator.requireCompletedSentence` from `settings.replaceOriginal`. When that flag is true, debounce still fires, but `handle` returns before extract/translate unless `SentenceExtractor.isComplete` sees a terminator at the caret. Overlay therefore stays hidden until `。` / `.` / `?` / `!` / newline. `FieldReplacement.evaluate` already attaches a trailing terminator only when one exists, so incomplete fragments can be replaced without that gate. Replace writes via `AXValue` already work; Control-Option-Return conflicting with other shortcuts is a user-recorded combination, not a write bug. Default remains Control-Shift-Return.

## Goals / Non-Goals

**Goals:**
- Stop gating the translation pipeline on sentence completeness when Replace Original is on.
- Keep capturing `sourceWithTerminator` (source plus optional terminator) for whatever fragment was translated, so replace still rewrites that fragment only.
- Align the Replace Original hint with overlay-on-pause behavior.

**Non-Goals:**
- No change to Carbon hotkey registration, conflict detection, or the Control-Shift-Return default.
- No migration of a user-recorded Control-Option-Return shortcut.
- No keystroke-injection fallback when `AXValue` writes fail.
- No change to Copy Translation or overlay chrome.

## Decisions

### D1: Drop the completeness gate; keep pause debounce

Set `requireCompletedSentence` to false (or remove the flag) even when Replace Original is on. Translation continues to wait for `InputDebouncer` using the existing speed setting. Overlay and speech follow `acceptTranslationResult` as they do today.

Alternatives considered: keeping the terminator gate and only documenting it was rejected; the user needs the overlay while composing. Translating on every keystroke was rejected; pause debounce is already the product default.

### D2: Replace the translated fragment, terminator optional

Keep `FieldReplacement.evaluate(fieldText:source:)` at request time. For an in-progress fragment, `sourceWithTerminator` is the source with terminator length 0. For a completed sentence, it still includes the trailing terminator. `FocusedFieldReplacer` continues to search backwards for that exact substring and write `prefix + translation + suffix`.

Alternatives considered: replacing the entire field was rejected earlier. Requiring a terminator before replace was rejected because overlay and replace should share the same current fragment.

### D3: Leave shortcut defaults and recorded values alone

Do not change `ReplaceShortcut.controlShiftReturn`. Do not treat Control-Option-Return as a product default. Users who recorded a conflicting combination can record another one in Settings; this change does not rewrite stored shortcuts.

Alternatives considered: shipping a new default or detecting OS-level conflicts would not fix overlay-on-pause and would surprise people who already recorded a working combination.

### D4: Hint copy only in `L10n`

Update `replaceOriginalHint` in Chinese and English. No new Settings control.

## Risks / Trade-offs

- [User presses replace while still composing] → Mitigation: that is the intended commit; they can undo in the host app. Overlay still does not write the field by itself.
- [User keeps typing after a pause, then presses replace] → Mitigation: existing stale-source check skips the write if the fragment is gone.
- [Some apps still ignore `AXValue` writes] → Mitigation: unchanged fail-closed behavior; overlay remains.
- [Users who recorded Control-Option-Return still hit conflicts] → Mitigation: they re-record in Settings; default stays Control-Shift-Return.

## Migration Plan

1. Ship the gate removal. Existing Replace Original on/off and recorded shortcuts stay as stored.
2. Rollback is restoring `requireCompletedSentence = settings.replaceOriginal` and the previous hint strings.

## Open Questions

None.

## Context

See `proposal.md` for motivation and the translation spec delta for the behavior contract.

On Shortcut, `handleTranslateHotKey` calls `AccessibilityMonitor.snapshotNow()` → `readFocusedText(force: true)` → `InputCoordinator.translateNow` → `SentenceExtractor.extract`. Pause and Complete Sentence translate from the typing snapshot when the terminator is entered. The shortcut re-reads later, when the caret is typically after `。`.

`extract` already steps back one terminator and includes the mark, and unit tests with an explicit end-of-string caret pass. Two gaps still produce an empty or non-Chinese fragment that `emit` drops:

1. Caret mapping mixes `NSRange.location` (UTF-16) with `Array(String)` Character indices, and trims the string *before* applying the caret, so the caret can land on an empty slice after the last terminator.
2. `snapshotNow` always trusts the latest `kAXValueAttribute`. After CJK punctuation commit, some fields report empty (or only the following empty node). That read also overwrites `lastText`, so the last good sentence is lost.

## Goals / Non-Goals

**Goals:**
- Make caret-after-terminator extract the same sentence as caret-before-terminator.
- Keep a last-good field snapshot so shortcut can translate when the live AX value is empty.
- Keep mapping the caret in UTF-16, matching Accessibility ranges.

**Non-Goals:**
- Changing when Pause or Complete Sentence *start* a translation.
- New AX permissions, or scraping a different element than the focused field.
- Translating punctuation-only slices that never had Chinese.

## Decisions

### D1: Map the caret in UTF-16 on the untrimmed field, then select the sentence the terminator closed

In `extract`, convert `selectedRange.location` with `String.Index(utf16Offset:in:)` (clamped). Do not trim the field before that map. If the character immediately before the caret is a terminator, the current fragment is the sentence that mark closed, including sentence punctuation (newline still completes but is not included). If the slice at the caret is empty or has no Chinese and a previous sentence exists before that terminator, use that previous sentence.

Alternatives considered: leaving extract as-is and only fixing AX was rejected because an empty post-terminator slice is a real extract outcome. Walking forward from the caret was rejected; that is the next sentence, often empty.

### D2: Last-good snapshot for shortcut re-reads

Keep the last non-empty focused-field text (and range) on `AccessibilityMonitor`. Do not replace it with an empty `kAXValue` read. `snapshotNow` should: read AX; if extract/Chinese fails and last-good text for this element exists, build the snapshot from last-good text with the caret treated as after the last terminator. If AXStringForRange / character-count can recover a non-empty value the Value attribute missed, prefer that over last-good.

Alternatives considered: translating from `onSnapshot` cache only (no live read) was rejected; the user may have edited since the last poll. Ignoring empty AX without fallback leaves the reported bug in IME-heavy apps.

### D3: `translateNow` stays the single shortcut entry

Do not add a second extract path in `AppState`. After snapshot recovery, `translateNow(..., force: true)` is enough so `lastSentence` does not suppress a retry.

## Risks / Trade-offs

- [Last-good text could be stale if the user cleared the field] → Mitigation: only fall back when the live read has no Chinese; empty live value after a clear should still no-op if last-good is from a previous session/element (clear last-good on focus change, already `removeObserver` / `onFocusChanged`).
- [Fallback after the first period when a second sentence has started] → Mitigation: if live text has Chinese after the caret, that fragment wins; last-good is only when live extract has no Chinese.
- [Some apps never expose the sentence through AX] → Mitigation: cannot invent text; no-op remains when both live and last-good lack Chinese.

## Migration Plan

1. Ship extractor + snapshot fallback with no UserDefaults changes.
2. Rollback is reverting extract caret mapping and `snapshotNow` last-good behavior.

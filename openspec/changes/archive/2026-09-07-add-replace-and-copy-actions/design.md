## Context

See `proposal.md` for motivation. Today `InputCoordinator` debounce-extracts the current sentence, `AppState` translates it, and `OverlayCoordinator` shows English. `AccessibilityMonitor` only reads `kAXValueAttribute`. There is no global hotkey and no clipboard action. This change adds two independent opt-in shortcuts sharing one pending English result: replace writes the focused field; copy writes the pasteboard.

## Goals / Non-Goals

**Goals:**
- Gate translation on sentence terminators only while Replace Original is on.
- Keep overlay (and existing speech) as the automatic output.
- Write the focused field only on the replace shortcut; write the pasteboard only on the copy shortcut.
- Register and unregister two process-wide hotkeys from Settings without a third-party package.

**Non-Goals:**
- No simulated copy/paste, Cmd-A, or keystroke injection as a write fallback.
- No replacing the entire field when earlier sentences already exist.
- No combining replace and copy onto one shortcut.
- No system notification or toast when copy succeeds; the overlay is enough feedback.
- No new TCC prompt beyond Accessibility (already required to read input). Replace writes use that permission; copy uses the general pasteboard.

## Decisions

### D1: Overlay still translates automatically; shortcuts only commit an action

After a terminator (Replace Original on) or a pause (Replace Original off), run translate → overlay (and speech). Hold the latest accepted English text plus, for replace, the source sentence/range. Hotkeys apply that payload. They do not start a new translation by themselves.

Alternatives considered: translating only on a shortcut would hide English until commit. Auto-writing the field was rejected earlier; copy-on-translate was rejected because the user asked for a shortcut.

### D2: Completeness uses the existing terminator set, and only for Replace Original

Reuse `SentenceExtractor` boundaries: `。？！.?!；;` and newline. Replace Original submits only when the caret is immediately after a terminator. Copy Translation does not change when translation starts.

Alternatives considered: gating copy on completeness as well was rejected; copy should work with today’s pause-based overlay when Replace Original is off.

### D3: Reconstruct `AXValue` for replace; `NSPasteboard` for copy

Replace: re-read the focused element. If it still contains the pending source plus trailing terminator, build `prefix + translation + suffix`, set `kAXValueAttribute`, then set `kAXSelectedTextRangeAttribute` after the inserted English.

Copy: write the pending English string to `NSPasteboard.general` as a string. Do not change selection or field text. Do not clear the pasteboard on a no-op.

Alternatives considered: selecting the sentence and using `AXSelectedText` is more fragile. Copying via simulated ⌘C would clobber the user’s current selection.

### D4: Two Carbon hotkeys, each consuming its combination

Register each enabled shortcut with `RegisterEventHotKey` and distinct hot-key IDs so they work while another app is focused and do not insert into the field. Unregister a hotkey when its setting is off, live translation is paused, or that shortcut changes. Persist `keyCode` plus modifier flags per action.

Settings uses click-to-record (next key-down commits; Escape cancels). No ShortcutRecorder dependency.

Defaults: replace **⌃⇧↩**, copy **⌃⇧C**. If the user records the same combination for both, last registration wins at the OS level; Settings SHOULD still store both values as recorded.

Alternatives considered: one shared shortcut with a modifier for copy was rejected because the user asked for a similar, separate action.

### D5: One pending payload, two one-shot consumers

Keep the latest accepted translation (and replace range when Replace Original produced it). Replace shortcut writes if the range still matches; if that sentence is still in flight, apply replace when it is accepted. Copy shortcut copies if English is ready; if in flight, copy when that generation is accepted. After a successful replace, clear the replace range. A successful copy does not clear the payload, so the user can copy again or then replace.

Alternatives considered: separate queues per action add complexity without a user-visible gain.

## Risks / Trade-offs

- [Many apps ignore `AXValue` writes, especially Electron/Chrome] → Mitigation: fail closed for replace; overlay and copy still work.
- [Hotkey conflicts] → Mitigation: distinct defaults; user-recordable; unregistered when the matching setting is off.
- [Write races with continued typing] → Mitigation: re-read and compare source range immediately before set; skip if mismatched.
- [Copy overwrites the user’s clipboard] → Mitigation: only on an explicit shortcut while the setting is on; no-op if there is no translation.
- [Carbon hotkey API is old] → Mitigation: isolate behind a small hotkey type that can hold two IDs.

## Migration Plan

1. Ship both actions off. Existing users keep pause-based overlay translation.
2. Missing UserDefaults keys map to off + ⌃⇧↩ / ⌃⇧C.
3. Rollback is reverting the gate, hotkeys, write, and pasteboard path; stored keys can remain unused.

## Open Questions

None. Shortcut defaults and “overlay first, shortcuts commit” are recorded above.

## Context

See `proposal.md` for motivation and the settings spec delta for the behavior contract.

The Translation page already has `pauseCommitDelay` as a slider and `translationTiming` as a picker. The slider currently sits above the picker and is always visible. `SettingsStore` already persists the delay independently of timing. Complete Sentence and On Shortcut already ignore that delay at translation time.

## Goals / Non-Goals

**Goals:**
- Place the pause-delay row immediately under Translation Timing.
- Hide that row unless timing is On Pause.
- Keep the stored delay while the row is hidden.

**Non-Goals:**
- Changing the 0.5–2.0 second range, persistence key, or InputCoordinator delay wiring.
- Resetting or disabling the stored delay when the user leaves On Pause.
- Changing Complete Sentence, On Shortcut, or translate-shortcut behavior.

## Decisions

### D1: Hide the row instead of disabling it

Use the same `if settings.translationTiming == .pause` pattern already used for the translate-shortcut recorder. A disabled slider would still advertise a setting that has no effect in the other modes.

Alternatives considered: leaving the slider visible but unused was rejected because that is the current confusing layout. Clearing or rewriting `pauseCommitDelay` on mode change was rejected because switching back to On Pause should restore the previous wait.

### D2: Timing first, then the mode-specific child row

Order is Translation Timing, then exactly one optional child: pause delay in On Pause, or the translate-shortcut recorder in On Shortcut. Complete Sentence has no child row.

Alternatives considered: showing the delay under the shortcut recorder was rejected because those two rows never appear together after this change. Keeping the delay above Timing was rejected by the requested layout.

## Risks / Trade-offs

- [Users who set a custom delay, then switch modes, may think the value was lost] → Mitigation: keep the stored value and show it again when they return to On Pause.
- [Language-resource / model settings stay below this block] → Mitigation: only the pause-delay row moves; later Translation-page sections stay in their current order.

## Migration Plan

1. Ship the visibility and row-order change with no UserDefaults migration. Existing `pauseCommitDelay` and `translationTiming` values stay as stored.
2. Rollback is restoring the always-visible slider above Translation Timing.

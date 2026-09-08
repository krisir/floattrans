## Context

See `proposal.md` for motivation and the translation/settings spec deltas for the behavior contract.

`AppState.acceptTranslationResult` already calls `speakIfAllowed` after showing the overlay. `SpeechPolicyEvaluator.shouldSpeak` currently takes only `speechEnabled`. Translation timing is already on `SettingsStore.translationTiming` (`.pause`, `.completeSentence`, `.shortcut`). Overlay, replace, and copy stay on their existing paths.

## Goals / Non-Goals

**Goals:**
- Gate auto-speak at the existing speech-policy check so On Pause never starts playback.
- Keep overlay updates and the auto-speak switch independent of that gate.
- Show a pause-only hint so the silent On Pause + auto-speak combination is not mysterious.

**Non-Goals:**
- Changing when translation starts, overlay text, replace/copy, or the built-in voice/rate/volume.
- Auto-switching timing when the user turns auto-speak on.
- Stopping in-flight speech when the user switches to On Pause (no speech should start in that mode after this change).
- Re-introducing voice, rate, volume, or auto-speak policy controls.

## Decisions

### D1: Extend the speech policy check with timing

Pass `settings.translationTiming` into `SpeechPolicyEvaluator.shouldSpeak` and return true only when speech is enabled and timing is `.completeSentence` or `.shortcut`. Keep `speakIfAllowed` as the single call site after a result is accepted.

Alternatives considered: skipping speech inside `InputCoordinator` was rejected because overlay and speech would fork at different layers. Checking for a terminator on the source string in pause mode was rejected because the spec forbids all On Pause speech, including punctuated fragments.

### D2: Hint only for the conflicting combination

Add one `L10n` caption under the auto-speak switch, visible when `speechEnabled && translationTiming == .pause`. Do not disable or hide the switch.

Alternatives considered: disabling the switch in On Pause was rejected because the user can leave auto-speak on while composing and switch to Complete Sentence later. Auto-changing timing when enabling speech was rejected as a surprising settings rewrite.

## Risks / Trade-offs

- [Users with auto-speak on and On Pause hear nothing after update] → Mitigation: show the hint; do not change stored timing.
- [On Shortcut can still speak an incomplete fragment] → Mitigation: that press is explicit; one translation, one utterance. Spec requires this.

## Migration Plan

1. Ship the gate and hint with no UserDefaults migration. Existing `speechEnabled` and `translationTiming` values stay as stored.
2. Rollback is ignoring timing in `shouldSpeak` and removing the hint string.

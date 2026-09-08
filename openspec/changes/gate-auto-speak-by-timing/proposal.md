## Why

On Pause timing translates the current fragment after every typing pause. If auto-speak is on, those in-progress overlays are read aloud and then interrupted by the next pause, so the user hears overlapping or repeated audio before the sentence is finished. Auto-speak should wait for a completed sentence or an explicit translate shortcut.

## What Changes

- When 朗读翻译结果 / Read Translations Aloud is on, auto-speak MUST fire only for translations produced in Complete Sentence or On Shortcut timing.
- On Pause translations MUST still update the overlay. They MUST NOT start speech, even if the fragment happens to end with a terminator.
- Turning auto-speak on MUST NOT change the selected timing mode. The switch stays available in every mode.
- When auto-speak is on and timing is On Pause, Settings SHALL show a hint that speech plays only in Complete Sentence or On Shortcut.
- Overlay, Replace Original, Copy Translation, and local speech synthesis stay as they are.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: Accepted overlay translations start auto-speak only in Complete Sentence and On Shortcut modes; On Pause never starts speech.
- `settings`: Translation-page Speech section explains that auto-speak does not play during On Pause.

## Impact

- `SpeechPolicyEvaluator` / `AppState.speakIfAllowed`, Translation-page hint copy in `L10n` and `SettingsUI`, and unit tests for speech gating.
- Timing modes, overlay display, and the auto-speak switch persistence are unchanged.

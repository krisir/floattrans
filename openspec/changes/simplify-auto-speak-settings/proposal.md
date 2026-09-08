## Why

The Speech section currently asks users to pick a voice, speaking rate, volume, and auto-speak policy. Most installed system voices do not sound like natural speech, and the extra controls make a simple “read translations aloud” feature feel like an audio mixer. Users only need a single switch.

## What Changes

- Keep the Translation-page Speech section, but show only the 朗读翻译结果 / Read Translations Aloud switch.
- Remove the voice picker, speaking-rate slider, volume slider, and auto-speak policy picker from Settings.
- When the switch is on, the app reads completed English translations aloud using a built-in English voice, rate, and volume. It no longer exposes those choices.
- Auto-speak policy is no longer user-selectable. The switch is the only gate: on speaks, off does not.
- **BREAKING**: Existing stored voice, rate, volume, and auto-speak policy values are ignored. Users who customized those controls lose that customization and get the built-in defaults.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `settings`: The Speech section on the Translation page exposes only the enable switch; voice, rate, volume, and auto-speak policy controls are removed, along with persistence of those values as user settings.
- `speech`: Completed-translation playback uses a built-in English voice, rate, and volume. When the auto-speak switch is on, translations are spoken; there is no hidden quiet-only gate.

## Impact

- Settings model, Settings UI, localization strings, speech playback call sites, and tests that currently persist or assert voice, rate, volume, and auto-speak policy.
- Overlay, translation timing, and local-only speech synthesis stay as they are.
- Leftover `UserDefaults` keys for the removed controls can remain unused without migrating other settings.

## 1. Settings Model and Localization

- [x] 1.1 Remove `speechVoiceIdentifier`, `speechRate`, `speechVolume`, `autoSpeakPolicy`, and `AutoSpeakPolicy` from `Settings.swift`, and stop reading or writing those `UserDefaults` keys
- [x] 1.2 Keep `speechEnabled` persisted with the existing off default for fresh and existing installs
- [x] 1.3 Remove unused voice, rate, volume, and auto-speak policy strings from `L10n.swift`; keep the Speech section title and auto-speak switch labels
- [x] 1.4 Update `SettingsStoreTests` so only the auto-speak switch persists, leftover voice/rate/volume/policy keys are ignored, and unrelated settings stay unchanged

## 2. Speech Playback

- [x] 2.1 Change `SpeechService.speak` to accept only translation text and apply the built-in rate `0.5` and volume `1.0`
- [x] 2.2 Use `AVSpeechSynthesisVoice(language: "en-US")` so playback does not depend on a premium voice that may not be downloaded
- [x] 2.3 Narrow `SpeechPolicyEvaluator.shouldSpeak` to `speechEnabled` only; do not skip speech based on audio context
- [x] 2.4 Update `AppState` so accepted translations call the simplified speak API and no longer pass stored voice, rate, volume, or policy

## 3. Settings UI

- [x] 3.1 Remove the voice picker, speaking-rate slider, volume slider, and auto-speak policy picker from the Translation-page Speech section
- [x] 3.2 Leave the Speech section with only the 朗读翻译结果 / Read Translations Aloud switch, still stopping speech immediately when turned off
- [x] 3.3 Remove the installed-voices helper from `SettingsUI.swift` if nothing else uses it

## 4. Tests and Verification

- [x] 4.1 Update speech policy tests to cover enabled versus disabled, with no audio-context cases
- [x] 4.2 Run the Swift test suite
- [ ] 4.3 Manually confirm the Translation Speech section shows only the switch in both 中文 and English
- [ ] 4.4 Manually confirm enabling the switch reads a completed English overlay aloud

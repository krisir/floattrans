## 1. Speech gate

- [x] 1.1 Extend `SpeechPolicyEvaluator.shouldSpeak` to take translation timing and return true only when auto-speak is on and timing is Complete Sentence or On Shortcut
- [x] 1.2 Pass `settings.translationTiming` from `AppState.speakIfAllowed` so On Pause overlay updates still skip speech
- [x] 1.3 Keep turning the auto-speak switch on from changing `translationTiming`

## 2. Settings hint

- [x] 2.1 Add bilingual `L10n` copy for the auto-speak timing hint
- [x] 2.2 Show that caption under the Speech switch only when auto-speak is on and timing is On Pause

## 3. Tests

- [x] 3.1 Cover enabled+pause (silent, including punctuated source), enabled+complete sentence, enabled+shortcut, and disabled in every mode
- [x] 3.2 Assert the Chinese and English hint strings
- [x] 3.3 Run the LiveEnglish unit tests and confirm they pass

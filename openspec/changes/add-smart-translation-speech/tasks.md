## 1. Settings Model and Localization

- [x] 1.1 Add speech-related settings types in `Settings.swift`: speech enabled, voice or locale, speech rate, speech volume, and auto-speak policy
- [x] 1.2 Persist speech settings in `SettingsStore` with tolerant defaults for fresh installs, existing installs, and invalid stored values
- [x] 1.3 Add localized Speech section strings and auto-speak option labels to `L10n.swift` for Chinese and English
- [x] 1.4 Extend `SettingsStoreTests` to verify speech defaults, persistence, and invalid value normalization

## 2. Speech Service

- [x] 2.1 Add a speech service abstraction that can speak text, stop current speech, and replace active speech with newer text
- [x] 2.2 Implement the production speech service with local macOS speech synthesis and configurable voice or locale, rate, and volume
- [x] 2.3 Ensure disabling speech or pausing live translation stops any current spoken output immediately

## 3. Audio Context Detection

- [x] 3.1 Add an audio context enum with `silent`, `mediaPlayback`, `communication`, and `unknownAudio`
- [x] 3.2 Add an injectable audio context detector boundary for production and tests
- [x] 3.3 Implement production detection using process-level Core Audio activity where available, excluding the FloatTrans process
- [x] 3.4 Classify input plus output activity or known active communication apps as `communication`
- [x] 3.5 Classify output-only activity as `mediaPlayback` and fallback active-device or uncertain states as `unknownAudio`
- [x] 3.6 Add unit tests for auto-speak policy decisions using a fake audio context detector

## 4. Translation Flow Integration

- [x] 4.1 Wire speech dependencies into `AppState` without changing the existing translation acceptance and overlay display order
- [x] 4.2 After a current translation result is accepted and displayed, evaluate speech enabled state and auto-speak policy
- [x] 4.3 Speak only when policy permits; skip speech while preserving overlay display when audio context blocks playback
- [x] 4.4 Add tests or focused seams that verify stale translation results do not speak and accepted results follow the selected policy

## 5. Settings UI

- [x] 5.1 Add a Speech section to the Translation settings page using the existing `SettingsRow` alignment
- [x] 5.2 Add controls for speech enablement, voice or locale selection, rate, volume, and auto-speak policy
- [x] 5.3 Ensure speech controls update the runtime speech configuration without requiring app restart
- [x] 5.4 Verify the Speech section labels and option names switch immediately between Chinese and English

## 6. Verification

- [x] 6.1 Run the Swift test suite
- [ ] 6.2 Manually verify speech off by default after clearing speech settings
- [ ] 6.3 Manually verify enabling speech reads a completed English overlay aloud when the Mac is quiet
- [ ] 6.4 Manually verify quiet-only mode skips speech while other media or a communication session is active, while still showing the overlay
- [ ] 6.5 Manually verify always-speak and never-auto-speak policies

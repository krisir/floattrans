## Context

See `proposal.md` for motivation. The current app completes translation in `AppState.translate`, accepts the newest session result, then calls `overlay.show(result, key:on:)`. Settings are stored in `SettingsStore` with `@Published` properties persisted to `UserDefaults`, and the Settings UI is built in `SettingsUI.swift` with a tabbed Translation page. The app already emphasizes low interruption: overlays appear passively, excluded apps are filtered before text is read, and translation uses local macOS capabilities where available.

## Goals / Non-Goals

**Goals:**
- Add speech as a separate service that can be invoked after a translation result is accepted.
- Keep translated text-to-speech local to macOS speech synthesis.
- Add an audio context detector that can conservatively decide whether automatic speech is appropriate.
- Persist speech settings and expose them in the existing Translation settings page.
- Make the first implementation testable without relying on real system audio state in unit tests.

**Non-Goals:**
- No speech recognition, dictation, microphone capture, or meeting transcription.
- No remote TTS providers.
- No per-application user rules for speech in the first version.
- No guarantee that all audio activity can be perfectly classified across every macOS version and application.

## Decisions

### D1: Add `SpeechService` around macOS speech synthesis

Use a small `SpeechService` abstraction owned by `AppState`, with operations to speak the latest accepted English translation and stop current speech. Internally it should use `AVSpeechSynthesizer` through AVFoundation. It should stop any active utterance before speaking a newer translation so the audible output tracks the overlay the user currently sees.

Alternatives considered: using deprecated AppKit speech APIs was rejected because they are not the current macOS direction. Embedding speech directly in `AppState.translate` was rejected because settings and audio-context behavior would make the translation method harder to test and maintain.

### D2: Gate automatic speech after result acceptance

Invoke speech only after `AppState.translate` has confirmed the result belongs to the current input session and the app remains enabled. The order should be: accept translation, update `translation`, show overlay, then evaluate speech. This preserves existing overlay behavior if speech fails, is disabled, or is skipped.

Alternatives considered: speaking before showing the overlay was rejected because it could create audible output for a translation the UI later discards. Triggering speech from inside `OverlayCoordinator` was rejected because overlay rendering should not own audio policy.

### D3: Model speech settings alongside existing settings

Add settings for:
- speech enabled
- voice or locale, default `en-US`
- speech rate
- speech volume
- auto-speak policy: quiet-only, always, never

Keep raw persisted values stable and tolerant of missing or invalid stored data, matching existing enum/default patterns in `SettingsStore`. The default should be speech off and quiet-only auto-speak so existing users do not suddenly hear audio after updating.

Alternatives considered: enabling speech by default was rejected because this is an audible behavior change. A single "read aloud" toggle was rejected because the user's pasted design specifically calls for smart quiet-only behavior and voice/rate controls.

### D4: Use an injectable audio context detector

Introduce an `AudioContextDetector` boundary with a production implementation backed by Core Audio and a test implementation for deterministic unit tests. The detector returns `silent`, `mediaPlayback`, `communication`, or `unknownAudio`. Speech policy consumes this enum rather than Core Audio details.

The production detector should prefer process-level audio activity when available: ignore the FloatTrans process, classify active output plus active input as communication, classify known communication bundle IDs with active output/input as communication, classify output-only activity as media playback, and treat uncertain active audio as unknown. If process-level APIs are unavailable or fail, fall back to checking whether the default output device is running somewhere and classify active output as unknown audio.

Alternatives considered: checking only the default output device is simpler but too conservative and less useful during real work. Relying only on bundle ID allowlists is fragile because open-but-idle meeting apps should not block speech.

### D5: Keep skipped speech passive

When quiet-only policy skips speech due to media, communication, or unknown audio, the overlay should still show the translation. A muted indicator may be added to the overlay, but it should be compact and non-blocking. The first implementation can skip silently if adding the indicator would require broad overlay layout changes.

Alternatives considered: showing an alert or notification was rejected because the purpose of quiet-only is to avoid interruption.

### D6: Localize settings through `L10n`

Add speech strings to the existing `L10n` enum and render controls in the existing Translation page layout. Use the existing `SettingsRow` label column so the new controls align with the rest of Settings.

Alternatives considered: creating a new Settings tab was rejected because speech belongs to translation behavior and the settings spec already organizes translation-related controls on the Translation page.

## Risks / Trade-offs

- [Core Audio process-level APIs vary by macOS version] -> Mitigation: isolate usage in the detector and provide a default-device fallback that errs toward not speaking.
- [Audio activity classification can be overly conservative] -> Mitigation: expose an "always speak" policy for users who intentionally want speech over other audio.
- [Adding speech can surprise existing users] -> Mitigation: default speech enabled to off for fresh and existing installs.
- [Unit tests cannot depend on live system audio] -> Mitigation: inject the audio context detector and speech service behind protocols or lightweight boundaries.

## Migration Plan

1. Add missing speech settings with defaults during `SettingsStore.init`; do not alter existing setting keys.
2. Ship speech disabled by default so existing users see no behavioral change until they opt in.
3. Rollback is safe by ignoring or removing the new speech keys; existing translation, overlay, and privacy settings remain unchanged.

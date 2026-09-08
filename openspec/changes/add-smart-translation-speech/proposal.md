## Why

FloatTrans already turns copied or focused Chinese text into English overlays, but users still need to read the result when speaking in live situations. Adding local macOS speech output lets the app become a lightweight speaking assistant while respecting the user's current audio context.

## What Changes

- Add optional text-to-speech playback for completed English translations using on-device macOS speech synthesis.
- Add smart auto-speak behavior that only reads translations aloud when the Mac appears quiet by default.
- Detect active system audio context before speaking, including other apps playing output and likely communication sessions using input/output activity.
- Add speech controls to Settings for enabling speech, selecting voice/locale, adjusting rate and volume, and choosing auto-speak behavior.
- Keep overlays visible even when speech is skipped, with optional muted-state feedback for skipped playback.

## Capabilities

### New Capabilities
- `speech`: Local speech output and audio-context-aware auto-speak behavior for translated text.

### Modified Capabilities
- `settings`: Speech settings controls, persistence, defaults, localization, and migration.

## Impact

- Affected code likely includes the translation completion pipeline, overlay presentation, Settings UI/model/persistence, localization strings, and macOS audio/speech services.
- New platform APIs: AVFoundation speech synthesis and Core Audio audio-process/device activity detection.
- Speech must remain fully local and must not send translated text to any additional service.

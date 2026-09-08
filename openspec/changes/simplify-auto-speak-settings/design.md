## Context

See `proposal.md` for motivation and the settings/speech spec deltas for the behavior contract.

Speech is already wired through `SettingsStore`, the Translation-page Speech section, `SpeechService`, and `SpeechPolicyEvaluator`. The store currently persists `speechEnabled`, `speechVoiceIdentifier`, `speechRate`, `speechVolume`, and `autoSpeakPolicy`. Playback reads those values after a translation result is accepted. Local `AVSpeechSynthesizer` output stays; the extra user-facing controls go away. Hidden quiet-only gating is removed because Core Audio often reports idle browsers and other processes as active, which makes a single switch look broken.

## Goals / Non-Goals

**Goals:**
- Collapse the Speech section to a single persisted enable switch.
- Move voice, rate, and volume into `SpeechService` so Settings no longer owns playback parameters.
- Speak whenever the switch is on. Do not hide a quiet-only or always/never policy behind that switch.

**Non-Goals:**
- No new TTS engine, remote voices, or downloadable-voice UI.
- No change to overlay or translation timing.
- No attempt to delete leftover `UserDefaults` keys on upgrade.

## Decisions

### D1: Drop unused speech settings from the store

Remove `speechVoiceIdentifier`, `speechRate`, `speechVolume`, and `autoSpeakPolicy` from `SettingsStore`, along with their normalization helpers and `AutoSpeakPolicy`. Keep `speechEnabled` as the only speech setting.

Alternatives considered: leaving the properties persisted but hidden was rejected because leftover values would still change playback and contradict the spec. Writing one-time migration into new keys is unnecessary when the values are ignored.

### D2: Let `SpeechService` use the system default English voice

`SpeechService.speak` should take only the translation text. Internally it uses `AVSpeechSynthesisVoice(language: "en-US")`, rate `0.5`, and volume `1.0`. Ranking installed voices by premium/enhanced quality was rejected after it selected downloadable premium voices that produce no audio.

Alternatives considered: hard-coding one identifier such as Samantha was rejected because identifiers differ across macOS versions. Picking the highest-quality listed `en-US` voice was rejected because listed premium voices are often not ready to speak.

### D3: The switch is the only speak gate

Change `SpeechPolicyEvaluator.shouldSpeak` to take `speechEnabled` only. Speak when the switch is on. Remove the always/never/quiet-only branches and the `AutoSpeakPolicy` type. Do not consult audio context before speaking.

Alternatives considered: keeping a hidden quiet-only rule was rejected because process-level audio APIs treat idle Chrome and similar apps as active output, so a quiet Mac still gets no speech. The single switch the user asked for must mean on equals speak.

### D4: Ignore leftover keys instead of wiping them

Stop reading and writing `speechVoiceIdentifier`, `speechRate`, `speechVolume`, and `autoSpeakPolicy`. Leave any existing values in `UserDefaults`. Rollback can restore the old controls and pick those values up again.

Alternatives considered: deleting the keys on first launch was rejected because it is irreversible and not required for correct behavior.

## Risks / Trade-offs

- [Users who chose Never auto-speak lose that behavior] → Mitigation: documented as breaking. Turning the switch off is the way to stay silent.
- [System default `en-US` may still sound compact on some Macs] → Mitigation: prefer a voice that actually plays over listing premium voices that stay silent.
- [Speech can overlap other media] → Mitigation: accepted. A single switch cannot also be a smart ducking control.

## Migration Plan

1. Ship with `speechEnabled` still defaulting to off and still persisted.
2. Ignore leftover voice/rate/volume/policy keys; do not rewrite other settings.
3. Rollback is the previous Speech section and store properties; leftover keys remain available if that build reads them again.

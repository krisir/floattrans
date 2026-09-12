## Context

See proposal.md. `LLMModelEditor` saves every `draft` change; `SettingsStore.llmModels` then calls `applyTranslationSettings()`, which cancels in-flight work, hides the overlay, and writes Keychain.

## Goals / Non-Goals

**Goals:**
- Persist and reconfigure once per committed edit (save or focus loss).
- Intermediate keystrokes stay in the editor draft.

**Non-Goals:**
- Changing model schema, backend protocols, or when language-pair changes take effect.

## Decisions

### D1: Commit on save or focus loss

Keep editing state local to `LLMModelEditor`. Write to `SettingsStore` on explicit Save or focus loss. API-key Keychain writes and `applyTranslationSettings()` happen only then. Discarding a draft must not change stored configuration.

**Alternative considered:** Debounce every keystroke into `SettingsStore`. That still reconfigures the live pipeline after the delay and still writes Keychain; a real commit boundary is clearer.

## Risks / Trade-offs

- [Model updates feel less immediate] → One commit after blur/save is better than cancelling translation per character.

## Migration Plan

Existing model values still load; only later edits use commit-based persistence.

## Open Questions

None.

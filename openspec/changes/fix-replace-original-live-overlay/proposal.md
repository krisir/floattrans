## Why

Turning on Replace Original currently delays translation until the user types a sentence terminator, so the overlay stays hidden while they are still composing. People need to see English as they pause, then press the replace shortcut when they are ready. The replace write itself works; Control-Option-Return is a known conflicting combination and is not the problem to fix.

## What Changes

- When Replace Original is on, use the same pause-based live translation as the rest of the app. Incomplete Chinese MUST still produce an overlay after the configured typing pause.
- Keep the focused field unchanged until the replace shortcut is pressed.
- On the replace shortcut, replace the current translated source fragment (including a terminator when one is present) with the English result, leaving earlier text unchanged.
- Keep the replace shortcut user-configurable. Do not change the default from Control-Shift-Return. Do not adopt Control-Option-Return as a default; that combination is commonly taken by other shortcuts.
- Update the Replace Original hint so it no longer says the user must finish a sentence before the overlay appears.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `translation`: Overlay translation while composing with Replace Original on; replace the full current source on the shortcut rather than waiting for a terminator to start translation.
- `settings`: Replace Original hint copy describes overlay-on-pause and shortcut-to-replace, not “wait until the sentence is complete.”

## Impact

- `InputCoordinator.requireCompletedSentence` and `AppState.setReplaceOriginal` should stop gating translation on terminators.
- Pending replace payload should capture the current source (with terminator when present) for incomplete and complete fragments.
- Settings hint strings in `L10n` need to match the new behavior.
- Tests around `SentenceExtractor.isComplete` and replace-original gating need to expect live overlay without a terminator.
- Copy Translation, overlay appearance, and the default Control-Shift-Return shortcut stay as they are.

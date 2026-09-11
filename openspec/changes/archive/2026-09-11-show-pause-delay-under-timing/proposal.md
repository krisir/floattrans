## Why

停顿后翻译 / Translate After Pause only affects On Pause timing, but Settings currently shows that slider above Translation Timing in every mode. Users who choose Complete Sentence or On Shortcut see a control that does nothing for them, and the delay sits away from the mode it belongs to.

## What Changes

- Move 停顿后翻译 / Translate After Pause to sit immediately below 翻译时机 / Translation Timing.
- Show the pause-delay slider only when timing is 超时翻译 / On Pause.
- Hide the slider when timing is 完整句子翻译 / Complete Sentence or 快捷键触发翻译 / On Shortcut.
- Keep the stored delay when the row is hidden. Switching back to On Pause restores the previous value without a reset.
- The On Shortcut translate-shortcut row stays visible only in that mode and still appears after Translation Timing (with the pause-delay row absent).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `settings`: Translation-page pause delay is a child of Translation Timing — placed directly under it and visible only in On Pause.

## Impact

- `SettingsUI` Translation-page row order and the pause-delay visibility condition.
- Existing `pauseCommitDelay` persistence, `InputCoordinator` delay wiring, and Complete Sentence / On Shortcut translation behavior stay as they are.

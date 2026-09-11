## 1. Settings layout

- [x] 1.1 Move the 停顿后翻译 / Translate After Pause row in `SettingsUI` so it sits immediately below Translation Timing
- [x] 1.2 Show that row only when `translationTiming` is On Pause; hide it for Complete Sentence and On Shortcut
- [x] 1.3 Keep the On Shortcut translate-shortcut row immediately below Timing when that mode is selected, and do not change `pauseCommitDelay` when the row is hidden

## 2. Verification

- [x] 2.1 Confirm stored `pauseCommitDelay` is unchanged after switching away from On Pause and back
- [x] 2.2 Run the LiveEnglish unit tests and confirm they pass

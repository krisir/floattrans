## 1. Settings UI

- [x] 1.1 Remove the read-only 翻译方向 / Direction `SettingsRow` from the Translation page in `SettingsUI.swift`
- [x] 1.2 Leave the 源语言 / Source Language and 目标语言 / Target Language pickers, language-resource row, speed, timing, and action controls in place

## 2. Strings and verification

- [x] 2.1 Delete unused `L10n.translationDirection` / `translationDirectionValue` helpers if nothing else references them
- [x] 2.2 Run `swift test`; in Settings → 翻译 confirm there is no Direction row, source and target pickers still change the pair, and language-resource status still follows the selected pair

## 1. Settings model and copy

- [x] 1.1 Add `TranslationTiming` (`pause`, `completeSentence`, `shortcut`) to Settings, persist it and a translate shortcut (default Control-Shift-T), and stop deriving completeness from Replace Original
- [x] 1.2 Add `L10n` strings for 翻译时机 / Translation Timing and the three options, plus translate-shortcut labels, in Chinese and English
- [x] 1.3 Update `SettingsStoreTests` for defaults, persistence, and missing-key migration without changing stored replace/copy values

## 2. Translation page

- [x] 2.1 Add the three-option timing control to the Translation page and show the translate-shortcut recorder only when On Shortcut is selected
- [x] 2.2 Changing timing or the translate shortcut takes effect immediately (hotkeys and input pipeline) without an app restart
- [x] 2.3 Update the Replace Original hint so it describes replacing the field, not waiting for a completed sentence to translate

## 3. Input pipeline and hotkey

- [x] 3.1 Drive `InputCoordinator` from `TranslationTiming`: pause uses speed debounce; complete sentence translates immediately when a terminator is at the caret; shortcut does not auto-translate
- [x] 3.2 Add `TranslationHotKeyAction.translate`, register it only when live translation is on and timing is On Shortcut, and on press translate the current focused fragment
- [x] 3.3 Keep Replace Original from forcing complete-sentence timing; store the extracted fragment (punctuation included when present) as the replace source
- [x] 3.4 Change `SentenceExtractor.extract` so trailing `。？！.?!；;` is part of the translated source, newline still ends a sentence but is not extracted, and replace does not append a second terminator

## 4. Tests

- [x] 4.1 Cover incomplete vs complete snapshots for pause and complete-sentence modes, and that shortcut mode does not translate from typing alone
- [x] 4.2 Cover extract/replace of a punctuated sentence (`我今天会晚一点。`) and of an in-progress fragment, plus stale-source skip
- [x] 4.3 Run the LiveEnglish unit tests and confirm they pass

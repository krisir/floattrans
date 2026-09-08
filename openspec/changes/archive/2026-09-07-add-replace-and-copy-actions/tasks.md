## 1. Settings Model and Localization

- [x] 1.1 Add Replace Original and Copy Translation flags plus two shortcuts (key code + modifiers; defaults Control-Shift-Return and Control-Shift-C) to `SettingsStore` with UserDefaults persistence
- [x] 1.2 Default missing keys to both actions off and the default shortcuts without changing unrelated existing settings
- [x] 1.3 Add Chinese and English strings for both toggles, shortcut labels, hints, and shortcut-recorder chrome in `L10n.swift`
- [x] 1.4 Extend `SettingsStoreTests` for fresh defaults, persistence, and existing-install missing-key defaults

## 2. Sentence Completion and Replace Range

- [x] 2.1 Add a complete-sentence check on the existing terminator set (`。？！.?!；;` and newline) so Replace Original submits only when the caret is after a terminator
- [x] 2.2 Add a pure helper that, given field text and the completed source, returns the range covering the source plus its trailing terminator (and prefix/suffix for reconstruction)
- [x] 2.3 Add unit tests for incomplete vs completed input, terminator variants, and replace-range construction when earlier sentences exist

## 3. Accessibility Write-Back and Clipboard

- [x] 3.1 Add a focused-field write API that re-reads `AXValue`, applies prefix + translation + suffix only when the pending source range still matches, then sets the selected range after the inserted English
- [x] 3.2 Leave the field unchanged and report failure when the write is rejected or the source range no longer matches
- [x] 3.3 Add a clipboard helper that writes a string to the general pasteboard and does not clear the pasteboard on a no-op
- [x] 3.4 Add tests or fake seams for stale-source skip, failed write, copy of ready text, and no-op copy when there is no translation

## 4. Global Shortcuts

- [x] 4.1 Isolate Carbon `RegisterEventHotKey` behind a small type that can register, replace, and unregister two consuming global combinations with distinct hot-key IDs
- [x] 4.2 Register the replace shortcut only while Replace Original is on and live translation is enabled; register the copy shortcut only while Copy Translation is on and live translation is enabled; unregister on pause, matching toggle off, or shortcut change
- [x] 4.3 On replace hotkey fire, apply the pending replace payload without activating FloatTrans or moving focus
- [x] 4.4 On copy hotkey fire, copy the pending English translation to the clipboard without activating FloatTrans, moving focus, or changing the field

## 5. Translation Pipeline

- [x] 5.1 When Replace Original is on, gate `InputCoordinator` so incomplete Chinese never starts translation; when off, keep pause-based extraction even if Copy Translation is on
- [x] 5.2 After an accepted overlay translation, store a pending payload (English text; plus source/terminator range when Replace Original produced it) and do not write the field or clipboard
- [x] 5.3 On replace shortcut: write if the payload is ready; if translation of the current completed sentence is still in flight, apply once that generation is accepted and the field still matches; otherwise no-op
- [x] 5.4 On copy shortcut: copy if English is ready; if translation is still in flight, copy once that generation is accepted; otherwise leave the clipboard unchanged
- [x] 5.5 Clear the replace range after a successful write, and clear the whole payload on focus/session change or when live translation is paused; turning Copy Translation off MUST NOT by itself clear a pending replace range

## 6. Settings UI

- [x] 6.1 Add Replace Original and Copy Translation toggles and shortcut recorders to the Translation page using existing `SettingsRow` alignment
- [x] 6.2 Click-to-record each shortcut (next key-down commits; Escape cancels) and refresh the matching registered hotkey immediately
- [x] 6.3 Verify labels switch with interface language without an app restart

## 7. Docs and Verification

- [x] 7.1 Update README (and landing page if it describes overlay-only output) to mention optional Replace Original and Copy Translation and their default shortcuts
- [x] 7.2 Run `swift test`
- [ ] 7.3 Manually confirm: incomplete Chinese does not translate when Replace Original is on; terminator shows overlay without rewriting the field; ⌃⇧↩ replaces the sentence in a writable native field; ⌃⇧C copies the English result without changing the field; each shortcut does nothing when its setting is off, translation is paused, or there is no ready translation

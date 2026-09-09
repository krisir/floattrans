## 1. Retention and store

- [x] 1.1 Add `HistoryRetention.none` with raw value `none` as the first `CaseIterable` case; `cutoffDate` returns `nil`
- [x] 1.2 Skip INSERT in `recordAndLoad` when retention is `.none` and return `load` so existing rows stay
- [x] 1.3 Add `TranslationHistoryStore.deleteAll()` (`DELETE FROM translation_history`) and `TranslationHistoryController.deleteAll()` that reloads `entries` to `[]` on success

## 2. Settings default

- [x] 2.1 Default missing or unknown `historyRetention` to `.none`; write `"none"` only when the key is missing; do not overwrite a stored `1d` / `7d` / `30d` / `6mo` / `forever` value

## 3. History page UI

- [x] 3.1 Add L10n for 不记录 / Do Not Record, 删除历史记录 / Delete History, and confirmation title, message, confirm, and cancel in 中文 and English
- [x] 3.2 On the History page, add a Delete History button next to export, disabled when `entries` is empty, with a `.confirmationDialog` whose confirm action is destructive and calls `deleteAll()`
- [x] 3.3 Keep `App.swift` calling `history.record(...)`; overlay, speech, replace, and copy MUST still run when retention is `.none`

## 4. Tests and copy

- [x] 4.1 Store tests: `.none` does not insert; switching to `.none` does not prune existing rows; `deleteAll` removes every row; cancel path is UI-only (store delete is not called)
- [x] 4.2 Settings tests: fresh/missing key defaults to `.none`; stored `.sevenDays` (or other) is kept; L10n assertions for the new History strings in both languages
- [x] 4.3 Update README history copy so the default is Do Not Record and delete-all is mentioned
- [x] 4.4 Run `swift test`; in Settings → History confirm the picker lists 不记录 first, a new translation is not stored when it is selected, existing rows remain until confirm, Cancel keeps rows, Confirm empties the list, and Delete is disabled when empty

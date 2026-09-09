## Why

Translation history currently always records completed translations and defaults to a 7-day retention. Users who do not want their source or translated text stored locally have no way to opt out, and no way to wipe records that are already on disk.

## What Changes

- Add a **不记录 / Do Not Record** option to the History retention picker.
- **BREAKING** (defaults only): fresh installs and installs with no stored retention default to **不记录** instead of 7 days. Existing stored retention values are kept.
- When **不记录** is selected, completed translations are not written to the local history store. Existing rows are left in place until the user deletes them.
- Add a **删除历史记录 / Delete History** action on the History page. Activating it shows a confirmation dialog; confirming deletes all local history records. Canceling leaves them unchanged.

## Capabilities

### New Capabilities

- `history`: Local translation-history recording policy, including the Do Not Record option, the do-not-record default, skip-on-record behavior, and confirmed delete-all.

### Modified Capabilities

- `settings`: History page retention picker includes Do Not Record as the default, and a delete-all control that requires confirmation.

## Impact

- `Sources/LiveEnglish/TranslationHistory.swift` — `HistoryRetention` gains a do-not-record case; store skips inserts and can delete all rows.
- `Sources/LiveEnglish/Settings.swift` — factory default for `historyRetention` becomes do-not-record; existing stored values stay as-is.
- `Sources/LiveEnglish/SettingsUI.swift` — picker option, delete button, and confirmation dialog on the History page.
- `Sources/LiveEnglish/App.swift` — recording path respects do-not-record (no new rows).
- `Sources/LiveEnglish/L10n.swift` — picker, button, and confirmation strings in 中文 / English.
- `Tests/LiveEnglishTests/TranslationHistoryTests.swift` — do-not-record skip, delete-all, and default-value coverage.
- README history copy should mention Do Not Record as the default and the delete action.
- No new dependencies, entitlements, or network behavior.

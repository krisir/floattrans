## Why

The Translation page already lets the user pick source and target languages. The extra 翻译方向 / Direction row only restates that pair as read-only text, so it takes space without adding a control.

## What Changes

- Remove the read-only 翻译方向 / Direction row from the Settings Translation page.
- Keep the 源语言 / Source Language and 目标语言 / Target Language pickers, stored language pair, local language-resource status, and runtime translation direction unchanged.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `settings`: The Translation page no longer shows a separate read-only 翻译方向 / Direction summary. Direction is chosen only through the source and target language pickers.

## Impact

- `Sources/LiveEnglish/SettingsUI.swift` — drop the Direction row from the Translation page.
- `Sources/LiveEnglish/L10n.swift` — remove unused 翻译方向 / Direction summary strings if nothing else references them.
- Existing `settings` requirement text still describes a read-only 中文 → 英文 direction row; that requirement must be updated to match the source/target pickers without the summary row.
- No persistence, engine, overlay, speech, or language-resource behavior changes.

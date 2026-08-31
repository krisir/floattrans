## Why

The settings window is Chinese-only while the menu bar still mixes English labels, shows a hard-coded translation direction (`中文 → English`), and opens About as a separate window. Users who prefer English (or Chinese) cannot switch the chrome language, and About belongs with the rest of app information inside Settings.

## What Changes

- Add **界面语言 / Interface Language** on the 通用 / General page with two options: **中文** (default) and **English**.
- Persist the choice and apply it immediately to the **menu bar** and **Settings window** (tab titles, page titles, labels, buttons, status text, window title).
- Add a fifth Settings tab **关于 / About** that hosts the existing About content (app name, version, description, links); remove the separate About window entry from the menu bar.
- **BREAKING (menu bar UX)**: remove the menu-bar caption that shows translation source → target (`中文 → English`).
- **BREAKING (settings tabs)**: Settings grows from four tabs to five (通用/翻译/悬浮窗/隐私/关于, or English equivalents when English is selected).
- Welcome / onboarding screens stay as they are (out of scope for this change).

## Capabilities

### New Capabilities
- `menubar`: menu bar extra contents — pause/resume, settings, quit; localization of those labels; removal of the translation-direction caption and the About menu item.

### Modified Capabilities
- `settings`: General page gains interface-language control; Settings UI language follows the selected interface language (replacing the Chinese-only chrome rule); add 关于 / About tab; tab count becomes five.

## Impact

- `Sources/LiveEnglish/Settings.swift` — persist `uiLanguage` (or equivalent) with default Chinese.
- `Sources/LiveEnglish/SettingsUI.swift` — language picker on General; string catalog / localized labels; new About tab; tab bar titles.
- `Sources/LiveEnglish/App.swift` — `MenuBarExtra` labels localized; remove direction caption and About button; drop or stop using `presentAbout` from the menu; settings window title follows language.
- Existing `AboutView` content reused inside the About settings page (standalone About window no longer opened from the menu bar).
- UserDefaults: new key for interface language; no migration beyond defaulting missing values to Chinese.

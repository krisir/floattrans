## 1. Model and string table

- [x] 1.1 Add `UILanguage` (中文 / English) to `SettingsStore` with UserDefaults persistence and default `.chinese` when missing
- [x] 1.2 Add a small `L10n` / `UIStrings` helper keyed by `UILanguage` covering menu bar + all Settings chrome strings (tabs, labels, buttons, statuses, About copy, window title)

## 2. Settings UI

- [x] 2.1 On the General page, add an interface-language control (中文 / English) bound to `settings.uiLanguage`, applying immediately
- [x] 2.2 Wire `SettingsView` (and window title via `onChange` / observer) so every tab, page title, group header, and control label uses the string helper for the current language
- [x] 2.3 Add the fifth tab 关于 / About reusing About content; localize About descriptive text for both languages
- [x] 2.4 Confirm the other four pages (翻译 / Overlay / Privacy / their English titles) render fully in the selected language with no leftover hard-coded opposite-language chrome

## 3. Menu bar

- [x] 3.1 Localize Pause/Resume, Settings, and Quit labels from `uiLanguage`
- [x] 3.2 Remove the `中文 → English` (translation direction) caption from the menu
- [x] 3.3 Remove the About menu item and stop opening the standalone About window from the menu bar

## 4. Verification

- [x] 4.1 Build the app with no errors
- [x] 4.2 With default 中文: confirm Settings has five Chinese tabs, General shows 界面语言 = 中文, menu bar is Chinese, no direction line, no About item
- [x] 4.3 Switch to English: confirm Settings title/tabs/labels and menu bar update immediately; About tab shows English descriptive text
- [x] 4.4 Relaunch and confirm the language preference persists; missing key still defaults to 中文

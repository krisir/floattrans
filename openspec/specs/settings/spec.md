## Purpose

Defines the behavior of the 浮译 (FloatTrans) settings window: its tab structure, default window size, interface language, the controls on each page, how permission and language-resource status are presented, and how settings values persist and migrate across app updates.

## Requirements

### Requirement: Settings window is organized into five tabs

The settings window presents its controls on five separate pages — 通用, 翻译, 悬浮窗, 隐私, 关于 (or General, Translation, Overlay, Privacy, About when the interface language is English) — selected through a tab bar at the top of the window. The tab bar SHALL show all five tabs as individual buttons in a single row. It SHALL NOT collapse any tab into an overflow control, sidebar, More menu, or single picker. Each page shows only its own controls, a page title, and its group headers; no other page's controls are visible.

#### Scenario: Opening settings shows the tab bar
- **WHEN** the user opens the settings window
- **THEN** the window title and tab bar use the selected interface language, all five tabs are visible as separate buttons (通用 / 翻译 / 悬浮窗 / 隐私 / 关于, or General / Translation / Overlay / Privacy / About), and the General page is displayed by default

#### Scenario: Switching pages
- **WHEN** the user selects a different tab
- **THEN** the page content switches to that tab's page and the selected tab is highlighted

#### Scenario: English tab titles stay in one row
- **WHEN** the interface language is English and the settings window is at its default width
- **THEN** General, Translation, Overlay, Privacy, and About are all visible as separate buttons in the top tab bar

### Requirement: Settings UI follows the selected interface language

Every visible string in the settings window — window title, tab titles, page titles, group headers, control labels, picker options, buttons, status text, and empty states — SHALL be shown in the selected interface language (Simplified Chinese or English). The product name 浮译 MAY remain as the brand where the app is named.

#### Scenario: Chinese interface
- **WHEN** the interface language is 中文 and any settings page is displayed
- **THEN** settings chrome strings are in Simplified Chinese

#### Scenario: English interface
- **WHEN** the interface language is English and any settings page is displayed
- **THEN** settings chrome strings are in English

#### Scenario: Language change applies immediately
- **WHEN** the user changes the interface language on the General page
- **THEN** the settings window title, tab titles, and visible page strings update to the new language without requiring an app restart, and the tab bar still shows all five tabs as separate buttons in a single row

### Requirement: Settings window uses a compact default height

The settings window SHALL open at a default content size of 520×480. Pages whose content exceeds the visible area SHALL remain scrollable. The window SHALL stay user-resizable and SHALL allow the user to shrink it below the previous 600pt content height.

#### Scenario: Default size on open
- **WHEN** the user opens the settings window
- **THEN** the content area is 520pt wide and 480pt tall

#### Scenario: Overflowing pages scroll
- **WHEN** the Overlay or Privacy page content is taller than the visible area
- **THEN** the page scrolls and no controls are permanently clipped off-screen

#### Scenario: User shortens the window
- **WHEN** the user resizes the settings window to a height below 600pt
- **THEN** the window shrinks and the current page remains usable by scrolling

### Requirement: Settings window stays reachable after switching apps

While the Settings window exists (visible or miniaturized), the running app SHALL be present in the Dock and the Cmd+Tab application switcher so the user can return to Settings without using the menu bar. Closing Settings SHALL remove that presence when no Welcome window remains. Choosing Settings from the menu bar SHALL still open Settings or bring the existing window to the front.

#### Scenario: Settings is reachable from the Dock
- **WHEN** the user opens Settings, switches to another application, and clicks the FloatTrans Dock tile
- **THEN** the Settings window becomes key and ordered front

#### Scenario: Settings is reachable from Cmd+Tab
- **WHEN** the user opens Settings, switches to another application, and selects FloatTrans in Cmd+Tab
- **THEN** the Settings window becomes key and ordered front

#### Scenario: Closing Settings restores menu-bar-only presence
- **WHEN** the user closes the Settings window and Welcome is not open
- **THEN** FloatTrans leaves the Dock and Cmd+Tab, and the menu bar extra remains available

#### Scenario: Menu bar still opens or focuses Settings
- **WHEN** Settings is already open and the user chooses Settings from the menu bar extra
- **THEN** the existing Settings window is brought to the front

### Requirement: General page shows core toggles and permission status compactly

The General page contains the toggles for enabling live translation and launch-at-login, an interface-language control with exactly two options — 中文 and English — and an Accessibility permission status area. Default interface language is 中文.

#### Scenario: Permission granted
- **WHEN** the app has accessibility permission and the user views the General page
- **THEN** the permission area shows only a small authorized indicator in a secondary style, with no button

#### Scenario: Permission missing
- **WHEN** the app lacks accessibility permission and the user views the General page
- **THEN** the permission area shows a yellow warning hint and a button that opens the system permission request

#### Scenario: Choosing interface language
- **WHEN** the user selects English (or 中文) in the interface-language control
- **THEN** the choice is persisted and the settings chrome and menu bar switch to that language immediately

### Requirement: Translation page shows direction, speed, and language resources

The 翻译 page shows the translation direction (中文 → 英文, read-only), the translation speed, and the language resource status. The selected translation speed SHALL be persisted and restored across app launches. On macOS 15 and later, the language-resource row SHALL be visible so the user can see installed, downloadable, or unsupported status.

#### Scenario: Speed is a segmented control
- **WHEN** the user views the 翻译 page
- **THEN** 翻译速度 is presented as a segmented control with exactly three options — 快速, 均衡, 舒缓 — and changing it takes effect for subsequent translations

#### Scenario: Speed survives relaunch
- **WHEN** the user selects a translation speed, quits the app, and launches it again
- **THEN** the previously selected speed is displayed and used for subsequent translations

#### Scenario: Languages installed
- **WHEN** the Chinese → English language resources are installed (where applicable) and the user views the 翻译 page
- **THEN** the 语言资源 row shows 中文 → 英文 · 已就绪 ✓ and no download button

#### Scenario: Languages not installed
- **WHEN** the Chinese → English language resources are not installed and the user views the 翻译 page
- **THEN** the 语言资源 row shows a download button; activating it downloads the resources and shows download progress, then shows 中文 → 英文 · 已就绪 ✓ on success

#### Scenario: Unsupported on this Mac
- **WHEN** Chinese → English translation is not supported on the current Mac
- **THEN** the 语言资源 row shows a brief message stating the pair is unsupported and no download button

#### Scenario: Language resources unavailable on older systems
- **WHEN** the running system does not support downloadable language resources
- **THEN** the 语言资源 row is hidden entirely

#### Scenario: Language resources visible on macOS 15
- **WHEN** the app is running on macOS 15 or later and the user views the 翻译 page
- **THEN** the 语言资源 row is visible and is not hidden solely because the system is older than macOS 26

### Requirement: Translation page includes translation timing

The 翻译 page SHALL include a 翻译时机 / Translation Timing control with exactly three options: 超时翻译 / On Pause, 完整句子翻译 / Complete Sentence, and 快捷键触发翻译 / On Shortcut. All visible labels SHALL follow the selected interface language. Changing the mode SHALL take effect without requiring an app restart. When On Shortcut is selected, the page SHALL show a translate-shortcut control; that control MAY be hidden in the other modes.

#### Scenario: Timing control is visible
- **WHEN** the user views the Translation page
- **THEN** the page shows Translation Timing with the three options and the currently selected mode

#### Scenario: Timing labels follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Translation page
- **THEN** the timing label and options are shown in Simplified Chinese

#### Scenario: Timing labels follow English interface
- **WHEN** the interface language is English and the user views the Translation page
- **THEN** the timing label and options are shown in English

#### Scenario: Shortcut recorder appears for On Shortcut
- **WHEN** the user selects On Shortcut
- **THEN** a translate-shortcut control is shown and recording a combination uses that combination for subsequent translate presses

#### Scenario: Shortcut recorder hidden for other modes
- **WHEN** the user selects On Pause or Complete Sentence
- **THEN** the translate-shortcut control is not shown

### Requirement: Translation page includes Replace Original and Copy Translation controls

The 翻译 page SHALL include toggles for 替换原文 / Replace Original and 复制译文 / Copy Translation, each with a shortcut control. All visible labels SHALL follow the selected interface language. Changing a toggle or shortcut SHALL take effect without requiring an app restart.

#### Scenario: Action controls are visible
- **WHEN** the user views the Translation page
- **THEN** the page shows Replace Original and Copy Translation switches and the current shortcut for each

#### Scenario: Controls follow Chinese interface
- **WHEN** the interface language is 中文 and the user views the Translation page
- **THEN** the Replace Original and Copy Translation labels and shortcut labels are shown in Simplified Chinese

#### Scenario: Controls follow English interface
- **WHEN** the interface language is English and the user views the Translation page
- **THEN** the Replace Original and Copy Translation labels and shortcut labels are shown in English

#### Scenario: User records a new shortcut
- **WHEN** the user records a new key combination in either shortcut control
- **THEN** that combination is shown as the current shortcut for that action and is used for subsequent presses of that action

### Requirement: Shortcut labels show punctuation keys as characters

Recorded and default shortcuts SHALL display ANSI punctuation keys as their unshifted characters, not as a numeric `Key N` fallback. Shift and Option in the combination MUST still appear as modifier glyphs; they MUST NOT change `[` into `{` or `]` into `}` in the label.

#### Scenario: Option-Shift-left-bracket displays as brackets
- **WHEN** the replace shortcut is Option-Shift-`[`
- **THEN** the shortcut control shows `⌥⇧[` and does not show `Key 30` or `⌥⇧{`

#### Scenario: Option-Shift-right-bracket displays as brackets
- **WHEN** the copy shortcut is Option-Shift-`]`
- **THEN** the shortcut control shows `⌥⇧]` and does not show a numeric key fallback or `⌥⇧}`

### Requirement: Replace Original and Copy Translation settings persist and default safely

Replace Original, Copy Translation, and their shortcuts SHALL persist across app launches. Fresh installs and existing installs without stored values SHALL default to both actions off, replace shortcut Option-Shift-`[`, and copy shortcut Option-Shift-`]`, without changing unrelated existing settings.

#### Scenario: Action settings survive relaunch
- **WHEN** the user changes Replace Original, Copy Translation, or either shortcut, quits the app, and launches it again
- **THEN** the previous values are restored

#### Scenario: Fresh install action defaults
- **WHEN** no prior Replace Original or Copy Translation settings exist
- **THEN** both actions are off, the replace shortcut is Option-Shift-`[`, and the copy shortcut is Option-Shift-`]`

#### Scenario: Existing install receives action defaults
- **WHEN** an existing install launches without stored Replace Original or Copy Translation settings
- **THEN** missing values use the fresh-install defaults without changing unrelated existing settings

#### Scenario: Stored shortcuts are not overwritten
- **WHEN** an existing install already has stored replace or copy shortcut key codes
- **THEN** those stored combinations are kept and are not replaced with Option-Shift-bracket defaults

### Requirement: Translation timing persists and defaults to On Pause

Translation timing and the translate shortcut SHALL persist across app launches. Fresh installs and existing installs without stored values SHALL default to On Pause and translate shortcut Control-Shift-T, without changing unrelated existing settings. The default translate shortcut MUST NOT be Control-Option-Return.

#### Scenario: Timing survives relaunch
- **WHEN** the user changes translation timing or the translate shortcut, quits the app, and launches it again
- **THEN** the previous values are restored

#### Scenario: Fresh install timing defaults
- **WHEN** no prior translation-timing settings exist
- **THEN** timing is On Pause and the translate shortcut is Control-Shift-T

#### Scenario: Existing install receives timing defaults
- **WHEN** an existing install launches without stored translation-timing settings
- **THEN** timing is On Pause and the translate shortcut is Control-Shift-T, without changing stored Replace Original, Copy Translation, or their shortcuts

### Requirement: Translation speed applies only in On Pause mode

The existing 翻译速度 / Translation Speed control SHALL continue to set the pause used for On Pause timing. Changing speed SHALL NOT delay Complete Sentence or On Shortcut translation.

#### Scenario: Speed still changes the pause
- **WHEN** timing is On Pause and the user changes translation speed
- **THEN** subsequent pause-based translations use the new speed

#### Scenario: Speed ignored for other modes
- **WHEN** timing is Complete Sentence or On Shortcut
- **THEN** translation starts when that mode’s trigger fires, without waiting for the translation-speed pause

### Requirement: Onboarding can install language resources on macOS 15

The first-run welcome flow SHALL offer Chinese → English language-resource install on macOS 15 and later, using the same installed / downloading / unsupported outcomes as Settings.

#### Scenario: Welcome shows language install on Sequoia
- **WHEN** a first-run user on macOS 15 reaches the permission / language step of onboarding
- **THEN** they can start Chinese → English language-resource installation from that step

#### Scenario: Unsupported Mac during onboarding
- **WHEN** Chinese → English is unsupported on the current Mac and the user is in onboarding
- **THEN** the language step shows that the pair is unsupported and does not present a working install action as if download were possible

### Requirement: Overlay page groups position, appearance, and behavior

The 悬浮窗 page is organized into three groups — 位置, 外观, 行为 — and offers a 预览悬浮窗 button.

#### Scenario: Position is a visual picker
- **WHEN** the user views the 位置 group
- **THEN** position is chosen by selecting one of three mini screen thumbnails labeled 右上, 底部居中, 右下, and the selection immediately applies to the overlay

#### Scenario: Appearance controls
- **WHEN** the user views the 外观 group
- **THEN** it shows 文字大小 with options 小 / 中 / 大 and 距顶部距离 as a slider in the 0–300 range, both taking effect immediately

#### Scenario: New-translation behavior
- **WHEN** the user views the 行为 group
- **THEN** it shows 新翻译出现时 with exactly two options — 替换上一条 and 向下堆叠 — 隐藏时间 as a slider in the 5–60 second range, and a 永不隐藏 checkbox

#### Scenario: Preview overlay
- **WHEN** the user clicks 预览悬浮窗
- **THEN** a sample translation overlay appears on the main screen using the current position, size, distance, and behavior settings

### Requirement: Hide-after is a slider plus a never-hide checkbox

The overlay hide behavior is controlled by a 隐藏时间 slider (5–60 seconds) and a separate 永不隐藏 checkbox. When the checkbox is on, overlays are never auto-hidden; when off, each overlay auto-hides after the slider's number of seconds.

#### Scenario: Never hide
- **WHEN** 永不隐藏 is checked and a translation overlay is shown
- **THEN** the overlay remains visible until the user closes it, replaces it, or disables translation

#### Scenario: Timed hide
- **WHEN** 永不隐藏 is unchecked and a translation overlay is shown
- **THEN** the overlay auto-hides after the number of seconds shown on the 隐藏时间 slider (5–60)

#### Scenario: Slider bounds
- **WHEN** the user drags the 隐藏时间 slider
- **THEN** the value stays within 5 and 60 seconds

### Requirement: History page retention picker includes Do Not Record

The Settings History page SHALL present retention as a picker whose options include 不记录 / Do Not Record plus the existing timed and forever options. Changing the selection SHALL take effect without requiring an app restart. All visible labels SHALL follow the selected interface language.

#### Scenario: Picker shows Do Not Record
- **WHEN** the user views the History page
- **THEN** the retention picker includes 不记录 when the interface language is 中文, or Do Not Record when it is English

#### Scenario: Selecting Do Not Record applies immediately
- **WHEN** the user selects Do Not Record
- **THEN** subsequent completed translations are not stored, without requiring an app restart

### Requirement: History page can delete all records with confirmation

The History page SHALL include a 删除历史记录 / Delete History control. Activating it SHALL present a confirmation dialog with a cancel action and a confirm action. Confirming SHALL remove every local history record and refresh the page to the empty state. Canceling SHALL close the dialog and leave records unchanged. Control and dialog strings SHALL follow the selected interface language. When the list is empty, the control SHALL be disabled.

#### Scenario: Delete control is visible
- **WHEN** the user views the History page and history contains at least one row
- **THEN** the page shows a Delete History control that can be activated

#### Scenario: Confirmation is required
- **WHEN** the user activates Delete History
- **THEN** a confirmation dialog is shown and no rows are deleted until the user confirms

#### Scenario: Confirm clears the list
- **WHEN** the user confirms the delete dialog
- **THEN** all history rows are gone and the page shows the empty-history message

#### Scenario: Cancel leaves the list unchanged
- **WHEN** the user cancels the delete dialog
- **THEN** the dialog closes and the previously visible rows remain

#### Scenario: Empty list disables delete
- **WHEN** the History page has no rows
- **THEN** the Delete History control is disabled

### Requirement: Privacy page lists excluded applications compactly

The 隐私 page shows a single explanatory line beneath the page title — 浮译不会读取或翻译以下应用内的文本。 — followed by one row per excluded application. Each row shows only the app icon, the app display name, and a remove control; bundle identifiers and per-row explanations are never shown. When an application is excluded, the system SHALL determine that exclusion before reading any Accessibility text from that application.

#### Scenario: Removing an application
- **WHEN** the user activates the remove control on an application row
- **THEN** the row disappears, the app is no longer excluded, and translation resumes inside that app immediately

#### Scenario: Adding an application
- **WHEN** the user clicks the ＋ 添加应用… button and picks an application
- **THEN** a row for that application appears in the list and translation is suppressed inside it immediately

#### Scenario: Excluded app text is not read
- **WHEN** the focused application has a bundle identifier in the excluded applications list
- **THEN** the system stops processing before requesting or reading the focused element's text through Accessibility

### Requirement: About tab presents app information

The Settings window SHALL include an 关于 / About tab that shows the product name 浮译 / FloatTrans, version, short description, license note, and the same repository and developer links previously shown in the standalone About window. The menu bar SHALL NOT open a separate About window.

#### Scenario: Viewing About
- **WHEN** the user selects the About tab
- **THEN** the page shows the app icon, product name, version, description, license note, and links for the repository and developer contact

#### Scenario: About content follows interface language
- **WHEN** the interface language is English
- **THEN** the About tab title and descriptive text are shown in English (product name may remain 浮译 where used as the brand)

### Requirement: About tab can check GitHub for updates

The Settings About tab SHALL include a 检查更新 / Check for Updates control. Activating it SHALL compare the running app's marketing version with the latest published GitHub release for `krisir/floattrans`. The check SHALL run only when the user activates the control; the app SHALL NOT poll GitHub in the background or download an installer. While a check is in progress, the control SHALL be disabled. Button label and status text SHALL follow the selected interface language.

#### Scenario: About shows the check control
- **WHEN** the user selects the About tab
- **THEN** the page shows a 检查更新 button when the interface language is 中文, or Check for Updates when it is English

#### Scenario: Newer release opens GitHub
- **WHEN** the user activates Check for Updates and GitHub's latest published release has a higher version than the running app
- **THEN** the default browser opens that release's GitHub page and the About tab does not claim the app is up to date

#### Scenario: Already up to date
- **WHEN** the user activates Check for Updates and the latest published GitHub release is the same version as the running app, or is not newer
- **THEN** the About tab shows localized status that the app is up to date and the browser does not open

#### Scenario: Check fails
- **WHEN** the user activates Check for Updates and the latest-release lookup fails (network error, unexpected response, or no published release)
- **THEN** the About tab shows localized status that the check failed and the browser does not open

#### Scenario: Check is in progress
- **WHEN** a check for updates is in progress
- **THEN** the Check for Updates control cannot be activated again until the check finishes

### Requirement: Settings persist and migrate cleanly

All settings SHALL persist across app launches. For existing installs, the previous hide-after configuration (a numeric 3–60 second value plus a separate never-hide flag) is preserved — the numeric value is re-clamped to the new 5–60 range and the never-hide flag is kept — and the previous overlay-behavior value is migrated to the renamed option without losing user intent. Missing interface-language values default to 中文. Missing Replace Original and Copy Translation values default to off with replace shortcut Option-Shift-`[` and copy shortcut Option-Shift-`]`. Missing translation-timing values default to On Pause with translate shortcut Control-Shift-T. Missing history-retention values SHALL default to Do Not Record. An existing stored history-retention value SHALL be kept.

#### Scenario: Migrating hide-after
- **WHEN** an existing install launches the new version with a stored hide-after value and a never-hide flag
- **THEN** the never-hide flag is preserved, and the stored numeric value is kept when within 5–60 seconds or clamped into that range otherwise (so an old 3–4 second value becomes 5)

#### Scenario: Migrating overlay behavior
- **WHEN** an existing install stored the old "Keep Previous" behavior value
- **THEN** the setting is preserved and displayed as 向下堆叠 (or Stack Below when the interface language is English)

#### Scenario: Fresh install defaults
- **WHEN** no prior settings exist
- **THEN** defaults are: live translation on, launch at login off, interface language 中文, translation speed Balanced / 均衡, translation timing On Pause, translate shortcut Control-Shift-T, overlay position bottom-center, text size medium, edge distance 48, new-translation behavior replace, hide-after 5 seconds, never-hide off, no excluded applications, Replace Original off, Copy Translation off, replace shortcut Option-Shift-`[`, copy shortcut Option-Shift-`]`, history retention Do Not Record

#### Scenario: Existing install without interface language
- **WHEN** an existing install has no stored interface-language value
- **THEN** the interface language defaults to 中文 and is written on first save or first change

#### Scenario: Existing install without history retention
- **WHEN** an existing install has no stored history-retention value
- **THEN** history retention defaults to Do Not Record and is written on first save or first change

#### Scenario: Stored history retention is not overwritten
- **WHEN** an existing install already has a stored history-retention value
- **THEN** that stored value is kept and is not replaced with Do Not Record

### Requirement: Consistent control alignment

Every settings page lays out controls with a fixed-width label column (150pt) and controls starting at the same horizontal position; labels of equal length align across pages.

#### Scenario: Alignment across pages
- **WHEN** the user switches between any two settings pages
- **THEN** the label column width and control start position are identical on both pages

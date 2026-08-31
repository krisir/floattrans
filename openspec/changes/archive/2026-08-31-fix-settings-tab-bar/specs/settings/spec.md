## MODIFIED Requirements

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

## ADDED Requirements

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

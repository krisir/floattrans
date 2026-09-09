## Why

FloatTrans is an `LSUIElement` menu-bar agent: Settings opens as a real window, but the app never appears in the Dock or Cmd+Tab. After switching to another app, the only way back is the menu bar extra, even though the Settings window is usually still open behind other windows.

## What Changes

- While Settings or the first-run Welcome window is open (including minimized), FloatTrans SHALL appear in the Dock and in the Cmd+Tab app switcher so the user can return to that window.
- Clicking the Dock icon SHALL bring the existing chrome window to the front (or unminimize it). Choosing Settings from the menu bar SHALL continue to open or focus Settings.
- When those chrome windows are closed and nothing else user-facing remains, the app SHALL return to menu-bar-only: no Dock icon, not in Cmd+Tab.
- Overlay panels and the hidden translation-host panel SHALL NOT make the app appear in the Dock.
- Default launch behavior stays a menu-bar agent. This is not a persistent Dock app.

## Capabilities

### New Capabilities

- `app-presence`: when the running app appears in the Dock and Cmd+Tab; chrome windows (Settings, Welcome) vs overlay/host; Dock-click and hide/unminimize behavior.

### Modified Capabilities

- `branding`: Dock shows the shipped AppIcon when the app is present in the Dock; launch alone no longer implies a Dock icon.
- `settings`: opening Settings participates in system app switching for as long as the window exists; closing it restores agent presence when no other chrome window remains.

## Impact

- `Resources/Info.plist` — keep `LSUIElement` as the launch default; runtime activation policy changes around chrome windows.
- `Sources/LiveEnglish/App.swift` — `presentSettings` / Welcome lifecycle, window close/miniaturize, `applicationShouldHandleReopen`, activation policy.
- Overlay and translation-host windows must stay excluded from presence.
- Existing AppIcon asset is reused; no new artwork.
- Menu bar extra contents, Settings tabs/controls, overlay behavior, and translation pipeline are unchanged.

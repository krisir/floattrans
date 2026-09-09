## 1. Presence helper

- [x] 1.1 Add a small helper that maps chrome-window state (Settings/Welcome open or miniaturized vs closed) to `.regular` vs `.accessory`, ignoring overlay and translation-host panels
- [x] 1.2 Keep `LSUIElement` as the launch default in `Info.plist`; do not remove it

## 2. Settings and Welcome wiring

- [x] 2.1 On first chrome show (`presentSettings` / Welcome), set `.regular`, then `unhide` and `activate(ignoringOtherApps: true)` before ordering the window front
- [x] 2.2 Observe close (and miniaturize) so a retained-but-closed Settings window is not counted as chrome; last chrome close sets `.accessory`
- [x] 2.3 Implement `applicationShouldHandleReopen` to deminiaturize and order front Settings if it exists, otherwise Welcome
- [x] 2.4 Do not flip to `.accessory` on resign active while chrome still exists; leave the SwiftUI `Settings` scene unwired

## 3. Verification

- [x] 3.1 After onboarding, confirm launch has no Dock tile and Cmd+Tab omits FloatTrans; showing overlay alone does not add one
- [x] 3.2 Open Settings: Dock tile uses the shipped AppIcon, Cmd+Tab includes FloatTrans; switch away and return via Dock and via Cmd+Tab; miniaturize then click Dock to restore
- [x] 3.3 Close Settings: Dock tile and Cmd+Tab entry go away; menu bar Settings still opens or focuses the window
- [x] 3.4 First-run Welcome shows Dock presence; closing Welcome with Settings closed restores agent presence; overlay still does not keep the Dock tile

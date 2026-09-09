## Context

See proposal.md for motivation. Specs: `specs/app-presence/spec.md` (when Dock/Cmd+Tab include FloatTrans), `specs/settings/spec.md` (Settings remains reachable after switching apps), `specs/branding/spec.md` (Dock tile uses the shipped AppIcon).

`Resources/Info.plist` sets `LSUIElement` so the process launches as an accessory agent: no Dock tile, not in Cmd+Tab. `AppState.presentSettings()` builds a retained `NSWindow` (`isReleasedWhenClosed = false`) and calls `NSApp.activate(ignoringOtherApps: true)` without changing `activationPolicy`. Overlay and the translation host are `NSPanel`s and must stay invisible to the Dock. First-run Welcome is the same class of chrome window as Settings. A SwiftUI `Settings` scene exists in `LiveEnglishApp` but the menu bar does not use it.

## Goals / Non-Goals

**Goals:**

- Toggle `NSApplication.activationPolicy` between `.accessory` and `.regular` from chrome-window lifetime, not from overlay/host lifetime.
- Treat a closed-but-retained Settings window as absent chrome (pointer non-nil is not enough).
- Handle Dock reopen / deminiaturize so a buried or minimized Settings window comes back.

**Non-Goals:**

- Making FloatTrans a persistent Dock app (`LSUIElement` stays the launch default).
- Migrating Settings onto the unused SwiftUI `Settings` scene.
- Changing overlay level, menu bar items, or Settings page contents.
- A global hotkey for Settings.

## Decisions

### 1. Keep `LSUIElement` and switch policy at runtime

Leave `LSUIElement` true so a launch with no chrome stays an agent. When the first chrome window is shown, call `NSApp.setActivationPolicy(.regular)`, then `unhide` and `activate(ignoringOtherApps: true)` before `makeKeyAndOrderFront`. When the last chrome window closes, call `setActivationPolicy(.accessory)`.

**Alternatives considered:** Removing `LSUIElement` (always occupies the Dock). A floating Settings panel (covers the overlay the user is configuring). Status-item popover (Settings is too large).

### 2. Chrome set is Settings + Welcome only

Count a window as chrome when it is Settings or Welcome and it is still in the window list as open or miniaturized. Overlay panels and `TranslationHostWindowController` never count. Resigning active MUST NOT flip back to `.accessory` while chrome still exists — that would recreate the original bug.

**Alternatives considered:** “Any `NSWindow` visible” (the host panel and overlay would flash the Dock). Switching to accessory on `applicationDidResignActive` (Cmd+Tab and Dock disappear as soon as the user leaves).

### 3. Observe close and miniaturize; keep the retained window pointer

`presentSettings` already reuses `settingsWindow` after close. Listen for `NSWindow.willCloseNotification` / miniaturize and recompute policy from “is this chrome window still a reason to stay `.regular`?”, not from `settingsWindow != nil`. Miniaturized chrome stays `.regular`. `applicationShouldHandleReopen` deminiaturizes and orders front Settings if present, otherwise Welcome.

**Alternatives considered:** Destroying the window on close (more churn, fights the existing reuse path). Ignoring miniaturize (user would have no Dock tile to restore a minimized Settings window).

### 4. One Settings surface: keep `presentSettings()`

Do not open the SwiftUI `Settings` scene from this change. Menu bar and Dock reopen both go through the existing `NSWindow`. Leaving the unused scene in place is acceptable; wiring it would risk two Settings windows.

**Alternatives considered:** Replacing the custom window with `openSettings()` (larger refactor, still needs the same policy toggle). Deleting the SwiftUI scene in this change (unrelated cleanup).

## Risks / Trade-offs

- [Policy switch does not show a Dock tile until `unhide`/`activate`] → Mitigation: always `unhide` then `activate` after `.regular`; verify on a real Dock, not only `orderFrontRegardless`.
- [Retained closed window keeps `.regular` forever] → Mitigation: close notification drives the count; closed retained windows are not chrome.
- [Overlay or host accidentally counted] → Mitigation: explicit allow-list of Settings and Welcome only.
- [Dock tile appearing/disappearing feels jumpy] → Mitigation: accepted; only chrome windows trigger it, and it matches other menu-bar utilities.

## Migration Plan

No persisted settings. Ship the policy toggle with Settings and Welcome. Rollback is revert: Settings is still openable from the menu bar, Dock presence goes away.

## Open Questions

None.

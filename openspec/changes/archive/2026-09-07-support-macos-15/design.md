## Context

See `proposal.md` for motivation. Production translation is selected in `AppState.makeEngine()`: macOS 26 uses `AppleTranslationEngine`, which constructs `TranslationSession(installedSource:target:)`; anything older uses `DemoTranslationEngine`. Settings `LanguageResourceRow` and welcome `LanguagePackSetupView` already use SwiftUI `.translationTask` / `LanguageAvailability` / `prepareTranslation()`, but both are wrapped in `#available(macOS 26.0, *)`. `Package.swift` and `project.yml` still declare macOS 13.0. Translation is invoked from `AppState` while the menu extra and settings window are often not on screen.

On macOS 15, `TranslationSession` cannot be constructed with `init(installedSource:target:)`. A session MUST come from `.translationTask` on a view that remains in the hierarchy; Apple documents that using a session after its view disappears or its configuration changes is fatal.

## Goals / Non-Goals

**Goals:**
- One production translation path that works on macOS 15 and later.
- Keep a session alive for the app lifetime, independent of the menu and Settings window.
- Reuse the existing language-availability UI states; only change when they appear.
- Align compile target, README, and landing-page requirements with macOS 15.

**Non-Goals:**
- No Foundation Models / Apple Intelligence LLM translation.
- No third-party or cloud translation provider.
- No official support for macOS 14 or earlier.
- No requirement that Intel Macs can download the pair; `.unsupported` remains the user-visible outcome.
- No dual production engines (26-only init plus 15 SwiftUI path) unless the unified host proves insufficient.

## Decisions

### D1: Unify production translation on a persistent `.translationTask` host

Use one always-mounted SwiftUI host (owned by `AppState`, not the menu extra) whose `.translationTask` supplies the session used for `translate`. Apply this on macOS 15 and macOS 26 so production does not depend on `TranslationSession(installedSource:target:)`.

Keep `TranslationCoordinator` as the cancellation/cache boundary. The engine (or a small session holder the engine calls) MUST only use the session while the host view is mounted.

Alternatives considered: keeping the macOS 26 initializer and adding a 15-only SwiftUI path was rejected because it doubles session lifetime rules. Putting `.translationTask` on `MenuBarExtra` or Settings was rejected because those views are not always in the hierarchy.

### D2: Host the task in a hidden, always-open AppKit window

Create a borderless, non-activating, off-screen or 1×1 `NSWindow` with an `NSHostingView` that runs `.translationTask` for zh → en. Order it in at launch and never close it while the process runs. Do not show it in the Window menu or Cycle Windows.

Use a stable `TranslationSession.Configuration` for the host. Do not `invalidate()` that configuration for ordinary translations.

Alternatives considered: an invisible SwiftUI `Window` scene can still be closed by the user or omitted from the window list inconsistently. A status-item attached view is not guaranteed to stay mounted with `.menuBarExtraStyle(.menu)`.

### D3: Drive language download through the same session, without killing it

Settings and onboarding SHOULD ask the shared holder to `prepareTranslation()` (and poll `LanguageAvailability`) instead of creating a second `.translationTask` that `invalidate()`s its configuration. Invalidating the production host’s configuration would destroy the live session.

`LanguageResourceRow` and `LanguagePackSetupView` keep their existing status copy and outcomes; only the session source changes. Remove `#available(macOS 26.0, *)` from those views (deployment target becomes 15.0, so Translation APIs are unconditionally available).

Alternatives considered: leaving a second `.translationTask` in Settings is acceptable only if it never invalidates the production host’s configuration. Prefer one session to avoid two download prompts and conflicting sessions.

### D4: Raise deployment target to macOS 15.0

Set `Package.swift`, `project.yml` (`deploymentTarget` / `MACOSX_DEPLOYMENT_TARGET`), and regenerate or edit the Xcode project to 15.0. Product copy (README, `docs/`) states macOS 15 or later. Demo/fallback production engine is removed; tests MAY keep a fake `TranslationEngine`.

Alternatives considered: leaving the target at 13.0 with runtime `#available(macOS 15.0, *)` was rejected because Translation is the product and 13–14 would still be a demo app. Documenting “15+ Apple Silicon only” as a hard launch requirement was rejected; use `LanguageAvailability` unsupported instead of blocking launch.

### D5: Onboarding language-pack step follows Settings

Ungate `LanguagePackSetupView` the same way as the Translation page row. If the pair is unsupported, show the existing unsupported message and do not imply a successful install.

## Risks / Trade-offs

- [Using a `TranslationSession` after the host view dies is a fatal error] → Mitigation: dedicated always-on window; never close it; do not invalidate the host configuration for each sentence.
- [System download UI requires a session that can request downloads] → Mitigation: `.translationTask` sessions can prompt; `installedSource` init cannot — another reason to avoid the 26-only initializer for production.
- [Intel or otherwise unsupported Macs still launch] → Mitigation: existing unsupported copy; no demo translations; overlays simply do not show fabricated English.
- [Hidden window may be treated as a visible window by some spaces/mission-control settings] → Mitigation: `isExcludedFromWindowsMenu`, non-activating panel/window, tiny off-screen frame; verify on 15 and 26.
- [Two `.translationTask` instances if Settings download is not migrated] → Mitigation: D3; if a temporary second task remains during implementation, it MUST use its own configuration and MUST NOT invalidate the host.

## Migration Plan

1. Ship a version whose deployment target and marketing requirement are macOS 15. Users on 15–25 move from Demo output to real translation after installing language packs.
2. Existing macOS 26 users keep the same overlay/settings behavior; only the session acquisition path changes.
3. No UserDefaults migration. Rollback is reverting the engine/host and gates; stored settings are unchanged.

## Open Questions

None. Hardware that cannot install the pair is already specified as unsupported in Settings.

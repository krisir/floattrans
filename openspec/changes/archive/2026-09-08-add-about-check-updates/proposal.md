## Why

浮译 is distributed from GitHub Releases, but Settings → About only shows a static version string and a repo link. Users cannot tell from the app whether a newer release exists, so they must remember to check GitHub themselves.

## What Changes

- Add a **检查更新 / Check for Updates** button on the Settings About tab.
- On click, compare the running app's marketing version with the latest GitHub release for `krisir/floattrans`.
- When a newer release exists, open that release's GitHub page in the default browser so the user can download it.
- When already up to date, or when the check fails, show localized inline status on the About tab (do not open a browser).
- This is a manual check only: no background polling, no in-app download, and no Sparkle/Sparkle-like auto-updater.

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `settings`: About tab gains a check-for-updates control, GitHub latest-release comparison, and status feedback (update found, already current, or check failed).

## Impact

- `Sources/LiveEnglish/App.swift` — `AboutView` gains the button, loading/status UI, and the check action.
- `Sources/LiveEnglish/L10n.swift` — localized button and status strings for 中文 / English.
- New small helper (or equivalent) to query GitHub Releases and compare versions against `CFBundleShortVersionString`.
- Tests for version comparison and latest-release parsing (network mocked).
- Outbound HTTPS to `api.github.com` when the user clicks the button; no new UserDefaults or settings keys.
- README / landing page are unchanged unless the About copy needs a one-line note.

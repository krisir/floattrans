## Context

See proposal.md for motivation. Settings → About (`AboutView` in `App.swift`) shows icon, product name, a hard-coded `L10n.version` string (`0.1.0`), description, and links to `https://github.com/krisir/floattrans` and the developer email. `Resources/Info.plist` already has `CFBundleShortVersionString` = `0.1.0`. Releases are published on GitHub (`krisir/floattrans`). The app is not sandboxed, so HTTPS to `api.github.com` needs no new entitlement. Specs: `specs/settings/spec.md` (About check-for-updates).

## Goals / Non-Goals

**Goals:**

- Manual latest-release lookup against GitHub when the user clicks the About button.
- Compare that release to the running marketing version and either open the release page or show inline status.
- Keep the check testable without hitting the network.

**Non-Goals:**

- Sparkle, in-app download, install, or silent background update.
- Checking on launch, on a timer, or when About appears.
- GitHub authentication, changelog UI, or release-note display inside the app.
- Changing how DMGs are built or published.

## Decisions

### 1. GitHub Releases API, not Sparkle and not HTML scraping

`GET https://api.github.com/repos/krisir/floattrans/releases/latest` with a descriptive `User-Agent` (GitHub requires one). That endpoint returns the latest **non-prerelease, non-draft** release. Decode `tag_name` and `html_url`. Use `URLSession` — no new SPM dependency.

**Alternatives considered:** Sparkle + appcast (in-app install, signing/feed work, out of scope). Scraping `/releases` HTML (fragile). `git` tags via the Git refs API (includes tags that are not published releases).

### 2. Marketing version from the bundle; tags compared as dotted numbers

Installed version is `CFBundleShortVersionString` (fallback empty → treat as check failed). Display the same value in About instead of the hard-coded `L10n.version` string so the label and the check cannot drift. Strip a leading `v`/`V` from `tag_name`. Compare by splitting on `.` and comparing integer components left-to-right (missing components = 0). A remote version is “newer” only when that compare is strictly greater. Equal or lower → up to date.

**Alternatives considered:** string equality only (misses `0.2.0` vs `0.1.9`). Full semver with pre-release labels (unnecessary while `/releases/latest` skips prereleases).

### 3. Open the release `html_url` in the default browser

When newer, `NSWorkspace.shared.open` the release’s `html_url` (the specific tag page, e.g. `/releases/tag/v0.2.0`). Do not open the generic repo or `/releases` list. Do not open a browser on up-to-date or failure.

**Alternatives considered:** always open `/releases/latest` (less precise if the user should land on the version that beat them). Copy the DMG URL to the clipboard (user asked to open the release page).

### 4. Injectable checker; About owns UI state

A small `UpdateChecker` (name flexible) takes the current version and a fetch function so tests can feed JSON / errors. `AboutView` holds `@State` for idle / checking / upToDate / failed. Disable the button while `.checking`. Status text lives in `L10n`. No UserDefaults.

**Alternatives considered:** fire-and-forget from the button with no status (fails the “already up to date” and “check failed” scenarios). App-wide store (overkill for a one-shot About action).

## Risks / Trade-offs

- [Unauthenticated GitHub API rate limit ~60 requests/hour per IP] → Mitigation: check only on click; typical use is well under the limit. Failure path covers HTTP 403/429 as “check failed”.
- [Offline or `api.github.com` blocked] → Mitigation: spec’d failure status; no browser open.
- [Tag is not dotted numeric, e.g. `nightly`] → Mitigation: parse failure → check failed, same as a bad payload.
- [Debug/dev builds report `0.1.0` and look “up to date” after a real `0.1.0` release] → Mitigation: expected; shipping builds must keep plist version in sync with the GitHub tag (existing release process).

## Migration Plan

Ship with the About button. No settings migration. Rollback is revert of the About UI and checker.

## Open Questions

None — repo, manual check, and “open the GitHub release page when newer” were specified; Sparkle, background polling, and in-app download are out of scope.

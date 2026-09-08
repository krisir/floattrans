## 1. Update checker

- [x] 1.1 Add a small `UpdateChecker` (or equivalent) that GETs `https://api.github.com/repos/krisir/floattrans/releases/latest` with a `User-Agent`, decodes `tag_name` and `html_url`, and accepts an injectable fetch so tests can avoid the network
- [x] 1.2 Compare `CFBundleShortVersionString` to `tag_name` by stripping a leading `v`/`V` and comparing dotted integer components; strictly greater is newer, equal or lower is up to date; missing local version or unparseable tag is a failed check
- [x] 1.3 Map HTTP / decode / empty-release failures (including 403/429 and 404) to a failed check result that does not include a URL to open

## 2. About UI

- [x] 2.1 Change `L10n.version` to format the bundle marketing version instead of a hard-coded `0.1.0`
- [x] 2.2 Add localized strings for 检查更新 / Check for Updates, checking, up to date, and check failed
- [x] 2.3 On `AboutView`, add the button, idle / checking / upToDate / failed state, disable the button while checking, show status text, and open `html_url` with `NSWorkspace` only when a newer release is found
- [x] 2.4 Do not check on About appear, on a timer, or at launch

## 3. Tests and verification

- [x] 3.1 Add unit tests for version compare (`0.1.0` vs `v0.1.0`, `0.1.9` vs `0.2.0`, equal, lower remote) and for mocked payloads: newer → URL, same → up to date, error/invalid JSON/non-numeric tag → failed
- [x] 3.2 Add L10n assertions for the new About strings in both 中文 and English
- [x] 3.3 Run `swift test`; in Settings → About confirm the button label follows interface language, a newer mock/release opens the GitHub release page, up-to-date and failure stay in-app, and the button is disabled while a check is in progress

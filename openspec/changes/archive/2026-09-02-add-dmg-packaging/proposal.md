## Why

浮译 can already build a local `.app`, but the bundle is named `LiveEnglish.app`, the executable does not match `Info.plist`, and there is no DMG for sharing. People installing from outside the App Store need a drag-to-Applications disk image whose on-disk names line up, with optional Developer ID signing and notarization so Gatekeeper will open it.

## What Changes

- **BREAKING (install path / TCC)**: the packaged bundle is `FloatTrans.app` with executable `FloatTrans`, replacing `LiveEnglish.app` / `LiveEnglish`. Existing local copies should be replaced; Accessibility may need to be re-granted if the path or signature changes.
- Align `Scripts/build-app.sh` (and the Swift package product name) so the bundle, `Contents/MacOS` binary, and `CFBundleExecutable` are all `FloatTrans`.
- Keep user-visible names as 浮译 (`CFBundleDisplayName` / `CFBundleName`); Finder and the DMG show the English `.app` filename.
- Add a `create-dmg` release script that stages only `FloatTrans.app` and produces a drag-to-Applications DMG (`FloatTrans.app` → Applications).
- Sign local builds with ad-hoc identity as today. When a Developer ID identity is provided, sign with Hardened Runtime and a timestamp; optionally notarize and staple the DMG.

## Capabilities

### New Capabilities
- `distribution`: how 浮译 is packaged for install — on-disk bundle and executable names, DMG layout via `create-dmg`, and signing / notarization for distribution outside the App Store.

### Modified Capabilities
- (none — branding remains the visual identity spec; on-disk English names belong to distribution)

## Impact

- `Scripts/build-app.sh` — emit `FloatTrans.app` / `Contents/MacOS/FloatTrans`.
- `Package.swift` — executable product name `FloatTrans` (Swift target/module can stay `LiveEnglish`).
- `Scripts/build-dmg.sh` (new) — stage + `create-dmg`; optional Developer ID / `notarytool` / `stapler`.
- `.gitignore` — ignore `FloatTrans.app/`, `dist/`, `*.dmg`; drop or keep `LiveEnglish.app/` for leftover local builds.
- `README.md` — build, DMG, and Gatekeeper notes; `create-dmg` via Homebrew.
- Developer machine: `brew install create-dmg`. Apple Developer Program + Developer ID Application certificate only for notarized public builds.
- Runtime behavior, Accessibility onboarding, and Settings are unchanged aside from the install path / signature TCC note above.

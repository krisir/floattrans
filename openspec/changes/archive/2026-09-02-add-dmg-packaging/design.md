## Context

See proposal.md for motivation. Today:

- `Scripts/build-app.sh` copies the SPM binary to `LiveEnglish.app/Contents/MacOS/LiveEnglish` and ad-hoc signs with `codesign --sign -`.
- `Resources/Info.plist` already has `CFBundleExecutable` = `FloatTrans`, `CFBundleIdentifier` = `cc.kristar.floattrans`, and display names 浮译.
- `Package.swift` still exposes executable product `LiveEnglish`; the Swift target/module stays `LiveEnglish`.
- There is no DMG script. The app is not sandboxed (`com.apple.security.app-sandbox` is false), which is required for Accessibility monitoring.

Confirmed product choices: on-disk `FloatTrans.app`, executable `FloatTrans`, `create-dmg` for the installer window, Developer ID + `notarytool` + staple for public builds.

## Goals / Non-Goals

**Goals:**

- Make the SPM-packaged `.app` launchable: bundle name, Mach-O name, and `CFBundleExecutable` all `FloatTrans`.
- Add a `create-dmg` pipeline that stages only that `.app` and emits `dist/FloatTrans-<version>.dmg` (or `dist/FloatTrans.dmg`).
- Gate Developer ID / notarization on environment so contributors without a certificate still get a local `.app` and an unsigned-for-Gatekeeper DMG.

**Non-Goals:**

- Universal (`arm64` + `x86_64`) binaries; keep the current Apple Silicon SPM path unless a later change adds it.
- Custom DMG background artwork, volume icon, or EULA.
- Mac App Store / `.pkg` / Sparkle auto-update.
- Renaming `Sources/LiveEnglish/` or the Swift module.
- Changing Accessibility onboarding or entitlements beyond what signing already uses.

## Decisions

### 1. Rename at the package product and copy into `FloatTrans.app`

Set `Package.swift` product to `.executable(name: "FloatTrans", targets: ["LiveEnglish"])`. `build-app.sh` copies `.build/.../release/FloatTrans` to `FloatTrans.app/Contents/MacOS/FloatTrans`. Leave the target name `LiveEnglish` so tests and imports stay put.

**Alternatives considered:** only rename at copy time (binary stays `LiveEnglish` in `.build`); rejected because `swift run FloatTrans` and the bundle then disagree. Renaming the Swift target; rejected as a large, unrelated refactor.

### 2. `create-dmg` over hand-rolled `hdiutil` + AppleScript

New `Scripts/build-dmg.sh` depends on `create-dmg` (Homebrew). It MUST fail clearly if the tool is missing. Stage `dist/dmg-stage/FloatTrans.app` only (never the repo root). Typical flags: `--volname "FloatTrans"`, `--window-size 600 400`, `--icon-size 100`, `--icon "FloatTrans.app" 150 200`, `--hide-extension "FloatTrans.app"`, `--app-drop-link 450 200`, `--overwrite`, output under `dist/`.

**Alternatives considered:** raw `hdiutil` (more brittle Finder layout); `.pkg` (wrong UX for a menu-bar app).

### 3. Two-script flow; signing identity from the environment

- `build-app.sh`: always produce `FloatTrans.app`. Default `codesign --force --sign - --entitlements ...`. If `CODESIGN_IDENTITY` is set (Developer ID Application), sign instead with `--options runtime --timestamp --sign "$CODESIGN_IDENTITY"` and the same entitlements. Do not pass `--verify` on the sign invocation; verify in a separate command. Do not use `--deep` (single executable, no nested helpers).
- `build-dmg.sh`: invoke `build-app.sh`, stage, `create-dmg`. If `NOTARY_PROFILE` is set, `xcrun notarytool submit ... --keychain-profile "$NOTARY_PROFILE" --wait` then `xcrun stapler staple`. Credentials stay in the notarytool keychain profile, never on the command line.

`create-dmg --codesign` / `--notarize` may sign the DMG container; the `.app` MUST already be Developer ID-signed first. Prefer notarizing the DMG (what users download).

**Alternatives considered:** always require Developer ID (blocks contributors); put the app-specific password in the script (unsafe).

### 4. Ignore build outputs, document Homebrew + Gatekeeper

`.gitignore`: `FloatTrans.app/`, `dist/`, `*.dmg`; keep `LiveEnglish.app/` so leftover local bundles are not committed. README: `brew install create-dmg`, `zsh Scripts/build-app.sh`, `zsh Scripts/build-dmg.sh`, and that un-notarized DMGs need right-click Open.

Read version from `CFBundleShortVersionString` when naming the DMG if convenient; otherwise `FloatTrans.dmg` is acceptable.

## Risks / Trade-offs

- [Renaming the `.app` or switching from ad-hoc to Developer ID resets Accessibility TCC] → Mitigation: README notes replacing `LiveEnglish.app` and re-enabling 浮译 in Privacy settings; bundle ID stays `cc.kristar.floattrans`.
- [CI / headless `create-dmg` AppleScript layout fails] → Mitigation: local GUI release is the primary path; if needed later, `--skip-jenkins` (uglier window, still a valid DMG).
- [arm64-only DMG fails on Intel] → Mitigation: documented non-goal; system requirement already macOS 26 / Apple Silicon in practice.
- [Notarization rejected because executable/plist mismatch] → Mitigation: this change fixes that before submit; `notarytool log` on failure.

## Migration Plan

1. Land product rename + `build-app.sh` so `open FloatTrans.app` works locally.
2. Add `build-dmg.sh` and gitignore; developers install `create-dmg`.
3. Public release: set `CODESIGN_IDENTITY` and `NOTARY_PROFILE`, staple, distribute `dist/*.dmg`.
4. Rollback: restore previous script and `LiveEnglish.app` packaging; users delete `FloatTrans.app` if needed.

## Open Questions

None — bundle name, executable name, `create-dmg`, and optional notarization were confirmed before planning.

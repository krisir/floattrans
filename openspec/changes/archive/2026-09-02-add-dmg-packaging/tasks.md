## 1. Align package product and app bundle names

- [x] 1.1 Change `Package.swift` executable product name to `FloatTrans` (keep target/module `LiveEnglish`)
- [x] 1.2 Update `Scripts/build-app.sh` to emit `FloatTrans.app` and copy the release binary to `Contents/MacOS/FloatTrans`
- [x] 1.3 Confirm `Resources/Info.plist` `CFBundleExecutable` is `FloatTrans` and display names stay 浮译; do not copy entitlements into a user-facing location unless still required for signing
- [x] 1.4 Add `FloatTrans.app/`, `dist/`, and `*.dmg` to `.gitignore`; keep ignoring leftover `LiveEnglish.app/`

## 2. Signing

- [x] 2.1 Default `build-app.sh` to ad-hoc `codesign --force --sign -` with existing entitlements (no `--deep`, no `--verify` on the sign line)
- [x] 2.2 If `CODESIGN_IDENTITY` is set, sign with `--options runtime --timestamp` and that identity, then run a separate `codesign --verify --deep --strict`
- [x] 2.3 After a default (no identity) build, confirm `codesign -dv` reports ad-hoc and `open FloatTrans.app` launches

## 3. DMG release script

- [x] 3.1 Add `Scripts/build-dmg.sh` that calls `build-app.sh`, stages only `dist/dmg-stage/FloatTrans.app`, and fails with a clear message if `create-dmg` is missing
- [x] 3.2 Invoke `create-dmg` with volname `FloatTrans`, window 600×400, icon size 100, app icon at 150 200, Applications drop link at 450 200, hide-extension, `--overwrite`, output under `dist/`
- [x] 3.3 If `NOTARY_PROFILE` is set, submit the DMG with `notarytool --keychain-profile` and `--wait`, then `stapler staple`; if unset, still write the DMG and do not claim it is notarized

## 4. Docs and leftover references

- [x] 4.1 Update README build/run steps to `FloatTrans.app`, `swift run FloatTrans`, `brew install create-dmg`, and `zsh Scripts/build-dmg.sh`
- [x] 4.2 Document Gatekeeper (right-click Open for un-notarized builds), `CODESIGN_IDENTITY` / `NOTARY_PROFILE`, and that replacing `LiveEnglish.app` may require re-enabling Accessibility
- [x] 4.3 Sweep scripts, README, and comments for leftover `LiveEnglish.app` packaging paths (leave Swift module/source paths as `LiveEnglish`)

## 5. Verification

- [x] 5.1 Run `swift test` and `zsh Scripts/build-app.sh`; confirm `Contents/MacOS/FloatTrans` exists and matches `CFBundleExecutable`
- [x] 5.2 Run `zsh Scripts/build-dmg.sh` (create-dmg installed); mount the DMG and confirm only `FloatTrans.app` plus Applications, no repo source or `.build`
- [x] 5.3 Launch the packaged app and confirm UI display name remains 浮译

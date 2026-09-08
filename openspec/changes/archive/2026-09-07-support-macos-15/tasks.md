## 1. Deployment Target

- [x] 1.1 Set `Package.swift` platforms to macOS 15
- [x] 1.2 Set `project.yml` deployment target and `MACOSX_DEPLOYMENT_TARGET` to 15.0 for the app and tests
- [x] 1.3 Regenerate or update `FloatTrans.xcodeproj` so the Xcode target matches macOS 15.0

## 2. Persistent Translation Session

- [x] 2.1 Add a session holder that stores the `.translationTask` session and exposes `translate` plus `prepareTranslation` without invalidating the host configuration
- [x] 2.2 Add a hidden, non-activating, Window-menu-excluded AppKit window with an `NSHostingView` that mounts `.translationTask` for zh → en at launch and keeps it mounted for the process lifetime
- [x] 2.3 Wire `AppState` / `TranslationCoordinator` to the holder so production translation never uses `TranslationSession(installedSource:target:)` or `DemoTranslationEngine`
- [x] 2.4 On missing, downloading, or unsupported language resources, return no translation result instead of a demo or prefixed string

## 3. Settings and Onboarding

- [x] 3.1 Remove `#available(macOS 26.0, *)` around `LanguageResourceRow` so the 语言资源 row is visible on macOS 15+
- [x] 3.2 Route Settings language download through the shared session holder (`prepareTranslation` + `LanguageAvailability` polling) instead of invalidating a second `.translationTask`
- [x] 3.3 Remove the macOS 26 gate on welcome `LanguagePackSetupView` and use the same holder/status outcomes as Settings, including unsupported with no fake install success

## 4. Cleanup and Docs

- [x] 4.1 Remove unused macOS 26-only `AppleTranslationEngine` initializer path and production `DemoTranslationEngine` usage; keep a fake engine only in tests if needed
- [x] 4.2 Update README, landing page (`docs/index.html`, `docs/app.js`), and related copy so the stated requirement is macOS 15 or later, not macOS 26
- [x] 4.3 Add or adjust tests for coordinator/engine behavior when translation fails or resources are missing (no fabricated English)

## 5. Verification

- [x] 5.1 Run `swift test`
- [ ] 5.2 On macOS 15 (or 15.7), confirm Settings shows the language-resource row, download/install works when supported, and typing Chinese produces a real overlay with the menu and Settings closed
- [x] 5.3 Confirm missing or unsupported resources do not show demo/prefixed English, and onboarding offers language install on macOS 15
- [x] 5.4 On macOS 26, confirm existing overlay, Settings, and language-pack flows still work after the session-host change

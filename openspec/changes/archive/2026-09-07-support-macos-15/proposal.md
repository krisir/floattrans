## Why

FloatTrans currently documents and gates real translation behind macOS 26, even though Apple’s Translation framework and downloadable language packs have existed since macOS 15. Users on Sequoia (including 15.7) can launch the app but only get the Demo fallback, so the product’s actual floor is much higher than the platform capability.

## What Changes

- Treat **macOS 15** as the supported minimum for real on-device Chinese → English translation, language-pack install, and onboarding.
- Obtain `TranslationSession` in a way that works on macOS 15 (SwiftUI `.translationTask` on a persistent host), instead of using the macOS 26-only `TranslationSession(installedSource:target:)` path as the production engine.
- Show the Translation settings language-resource row and onboarding language-pack step on macOS 15+, instead of hiding them behind `#available(macOS 26.0, *)`.
- Raise the declared product requirement (README, landing page, and related copy) from macOS 26 to macOS 15. Raise the compile deployment target from 13.0 to 15.0 so it matches Translation framework availability.
- Stop using `DemoTranslationEngine` as the production engine on macOS 15–25. Keep demo/fake engines only for tests if needed.

## Capabilities

### New Capabilities
- `translation`: On-device Chinese → English translation via the system Translation framework on macOS 15+, including session lifetime and behavior when language packs are missing or unsupported.

### Modified Capabilities
- `settings`: Language-resource status and download on the Translation page (and matching onboarding) MUST be available on macOS 15+, not only macOS 26+. The “hide the row on older systems” requirement no longer applies to Sequoia.

## Impact

- `Sources/LiveEnglish/Models.swift` (`AppleTranslationEngine` / `DemoTranslationEngine` / `TranslationCoordinator`)
- `Sources/LiveEnglish/App.swift` (engine selection, persistent translation host, welcome language-pack step)
- `Sources/LiveEnglish/SettingsUI.swift` (language-resource row availability)
- `Package.swift`, `project.yml`, and generated Xcode project deployment target
- Product docs: `README.md`, `docs/index.html`, `docs/app.js`
- Tests around translation engine selection and language-availability UI states
- No new third-party dependencies; continues to use system `Translation`

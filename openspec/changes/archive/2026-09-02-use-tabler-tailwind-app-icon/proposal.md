## Why

浮译 still ships a generic chat-bubble translation AppIcon and uses SF Symbols (`waveform` / `pause`) in the menu bar. The product needs a consistent visual identity based on the Tabler Icons `brand-tailwind` mark for both the application icon and the menu bar status item.

## What Changes

- Replace the macOS **AppIcon** asset set with a new icon derived from Tabler Icons outline `brand-tailwind` (MIT): a light mark on a teal / Tailwind-style rounded square, exported at all required mac sizes.
- Replace the menu bar `MenuBarExtra` SF Symbol with a **template** rendering of the same `brand-tailwind` mark.
- **BREAKING (menu bar UX)**: the status item no longer switches between `waveform` and `pause`; pause/resume remains available only through the menu labels.
- Bundle the source SVG (and a short MIT attribution note) in the repo so the asset can be regenerated.
- Keep Settings About content as-is; it already displays `Bundle.main`'s app icon, so it picks up the new AppIcon automatically when built via the Xcode/`project.yml` path.

## Capabilities

### New Capabilities
- `branding`: application visual identity — Dock / Finder / About app icon derived from Tabler `brand-tailwind`, and shared mark assets used by the menu bar.

### Modified Capabilities
- `menubar`: menu bar extra icon uses the Tabler `brand-tailwind` template mark at all times instead of SF Symbols that change with pause state.

## Impact

- `Resources/Assets.xcassets/AppIcon.appiconset/` — replace PNGs (and keep `Contents.json` size map).
- `Resources/Assets.xcassets/` — add a template image set (e.g. `MenuBarIcon`) for the status item.
- `Sources/LiveEnglish/App.swift` — `MenuBarExtra` label switches from `systemImage:` to the custom image; remove enabled-based symbol swapping.
- `project.yml` / Xcode asset catalog — AppIcon name stays `AppIcon`; ensure the new menu-bar image set is included via existing `Resources/Assets.xcassets`.
- `Scripts/build-app.sh` — SPM-packaged `.app` currently omits the asset catalog; either document that AppIcon/menu-bar assets require the Xcode build, or extend the script so the packaged app includes compiled assets.
- Third-party: Tabler Icons `brand-tailwind` SVG under MIT; include attribution. This uses Tabler's icon artwork, not an official Tailwind CSS trademark asset.

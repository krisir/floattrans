## 1. Source artwork

- [x] 1.1 Add Tabler Icons outline `brand-tailwind.svg` under `Resources/Icons/` (upstream MIT SVG)
- [x] 1.2 Add `Resources/Icons/ATTRIBUTION.md` noting Tabler Icons MIT license and that this is not an official Tailwind CSS trademark asset

## 2. App icon assets

- [x] 2.1 Compose a teal / Tailwind-style rounded-square master (light brand-tailwind mark, padded for legibility at small sizes)
- [x] 2.2 Export and replace all `AppIcon-*.png` sizes required by `Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` (16/32/128/256/512/1024)
- [x] 2.3 Spot-check 16pt and 32pt exports for stroke clarity; adjust mark scale/stroke if needed

## 3. Menu bar template asset

- [x] 3.1 Add `MenuBarIcon` imageset to `Resources/Assets.xcassets` with black-on-transparent brand-tailwind PNGs (or PDF) at menu-bar sizes
- [x] 3.2 Set the imageset to render as a **Template Image** so the menu bar tints it in light/dark appearance

## 4. Wire menu bar

- [x] 4.1 Update `MenuBarExtra` in `Sources/LiveEnglish/App.swift` to use `MenuBarIcon` instead of `systemImage: waveform/pause`
- [x] 4.2 Confirm the status item glyph does not change when toggling pause/resume; menu labels still pause/resume correctly

## 5. Packaging

- [x] 5.1 Ensure Xcode/`project.yml` FloatTrans target still compiles `Resources/Assets.xcassets` with `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`
- [x] 5.2 Update `Scripts/build-app.sh` to compile/copy the asset catalog into the SPM-packaged `.app`, **or** document in the script that AppIcon/menu-bar assets require the Xcode build

## 6. Verification

- [x] 6.1 Build via Xcode (or xcodebuild) and confirm Dock / Finder show the new teal AppIcon
- [x] 6.2 Confirm the menu bar shows the brand-tailwind template mark while running and after pause
- [x] 6.3 Open Settings → About and confirm it shows the same new application icon

## Context

See proposal.md for motivation. Today:

- `Resources/Assets.xcassets/AppIcon.appiconset/` holds a chat-bubble “文” AppIcon used via `project.yml` (`ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`).
- `MenuBarExtra` in `App.swift` uses `systemImage: enabled ? "waveform" : "pause"`.
- About uses `NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)`, so it follows the bundled AppIcon when present.
- `Scripts/build-app.sh` (SPM `.app` packaging) copies only the binary + Info.plist and does **not** compile/copy the asset catalog.

Source artwork: Tabler Icons outline `brand-tailwind` (24×24 stroke SVG, MIT).

## Goals / Non-Goals

**Goals:**

- Ship a teal rounded-square AppIcon with a light brand-tailwind mark at all mac sizes already listed in `Contents.json`.
- Ship a menu-bar template image of the same mark and wire `MenuBarExtra` to it permanently.
- Keep SVG + attribution in-repo so assets can be regenerated.

**Non-Goals:**

- Redesigning Settings tab icons, Welcome UI, or overlay chrome.
- Changing pause/resume menu labels or other menubar behavior beyond the status-item glyph.
- Claiming official Tailwind CSS branding; this is Tabler’s MIT icon only.
- Full SPM asset-catalog parity beyond what is needed for the chosen packaging path (see Decisions).

## Decisions

### 1. App icon composition: light mark on teal squircle

Render the stroke mark in white / near-white on a teal gradient rounded square (Tailwind-adjacent cyan–teal), with comfortable padding so the mark stays legible at 16pt.

**Alternatives considered:** glyph-only / transparent (poor Dock presence); reuse current blue chat palette (rejected by product choice).

### 2. Menu bar: template image asset, always the same

Add an asset catalog imageset (e.g. `MenuBarIcon`) with “Render As: Template Image”, generated from the same SVG (black strokes on transparent). Use `MenuBarExtra`’s `image:` initializer or a custom `label:` `Image("MenuBarIcon")` so AppKit tints it for light/dark menu bar.

Do **not** dim or swap the icon when paused; pause/resume remains menu-text only (confirmed).

**Alternatives considered:** keep `pause` SF Symbol when disabled; dim opacity when paused — both rejected.

### 3. Source SVG + attribution in repo

Store the upstream SVG under something like `Resources/Icons/brand-tailwind.svg` and a short `Resources/Icons/ATTRIBUTION.md` (Tabler Icons MIT). Prefer regenerating PNGs from that SVG rather than editing pixels by hand when possible (`rsvg-convert`, `qlmanage`, or a small script).

### 4. Packaging: Xcode/`project.yml` is the AppIcon source of truth

`Assets.xcassets` is already a resource of the FloatTrans Xcode target. Primary verification path: build via XcodeGen/`FloatTrans.xcodeproj`.

For `Scripts/build-app.sh`: either (a) document that Dock/About icons require the Xcode build, or (b) extend the script to compile the asset catalog (`actool`) and install `Assets.car` / AppIcon into the `.app`. Prefer (b) if the script is still used for distribution; otherwise (a) is acceptable if called out in tasks.

### 5. About page needs no code change

Keep `AboutView`’s `NSWorkspace` icon lookup; updating AppIcon is sufficient for Xcode builds.

## Risks / Trade-offs

- [Pause no longer visible from the status glyph alone] → Mitigation: pause/resume menu labels already communicate state; accepted product trade-off.
- [Teal mark may be hard to see at 16×16] → Mitigation: thicken effective stroke / enlarge mark slightly when rasterizing small sizes; spot-check Retina menu bar and Dock.
- [SPM `build-app.sh` apps may still show a generic icon] → Mitigation: fix or document packaging (Decision 4).
- [Trademark confusion with Tailwind CSS] → Mitigation: attribution notes Tabler MIT artwork only; not an official Tailwind mark.

## Migration Plan

1. Land SVG + attribution, generate AppIcon PNGs and `MenuBarIcon` template assets.
2. Wire `MenuBarExtra` to the template image; remove SF Symbol swap.
3. Rebuild via Xcode; confirm Dock, menu bar, and About.
4. Optionally update `build-app.sh` so SPM-packaged apps get the same assets.
5. Rollback: restore previous AppIcon PNGs and `systemImage:` line if needed.

## Open Questions

None — pause-state and app-icon style were confirmed before planning.

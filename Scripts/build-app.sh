#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$ROOT/FloatTrans.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/FloatTrans" "$APP/Contents/MacOS/FloatTrans"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Compile AppIcon + MenuBarIcon asset catalog into the packaged app bundle.
# Merge actool's icon keys; without them Finder shows a generic blank app icon.
PARTIAL_PLIST="$(mktemp)"
xcrun actool \
  --output-partial-info-plist "$PARTIAL_PLIST" \
  --app-icon AppIcon \
  --platform macosx \
  --minimum-deployment-target 15.0 \
  --compile "$APP/Contents/Resources" \
  Resources/Assets.xcassets
if [[ -s "$PARTIAL_PLIST" ]]; then
  for key in CFBundleIconFile CFBundleIconName; do
    val="$(/usr/libexec/PlistBuddy -c "Print :$key" "$PARTIAL_PLIST" 2>/dev/null)" || continue
    /usr/libexec/PlistBuddy -c "Delete :$key" "$APP/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :$key string $val" "$APP/Contents/Info.plist"
  done
fi
rm -f "$PARTIAL_PLIST"

ENTITLEMENTS="$ROOT/Resources/LiveEnglish.entitlements"
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    "$APP"
  codesign --verify --deep --strict "$APP"
else
  codesign --force --sign - --entitlements "$ENTITLEMENTS" "$APP"
fi
echo "Built $APP"

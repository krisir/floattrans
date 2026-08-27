#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build -c release
APP="$ROOT/LiveEnglish.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/arm64-apple-macosx/release/LiveEnglish "$APP/Contents/MacOS/LiveEnglish"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/LiveEnglish.entitlements "$APP/Contents/Resources/LiveEnglish.entitlements"
codesign --force --deep --sign - --entitlements Resources/LiveEnglish.entitlements "$APP"
echo "Built $APP"

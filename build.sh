#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p bin

echo "==> building CLI"
clang -fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter \
    -framework Foundation -framework IOKit \
    -o bin/tbright src/tbright.m src/TBCore.m

echo "==> building menu bar app"
APP="bin/TouchBarBrightness.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

clang -fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter \
    -framework Cocoa -framework Foundation -framework IOKit \
    -o "$APP/Contents/MacOS/TouchBarBrightness" src/tbapp.m src/TBCore.m

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>TouchBarBrightness</string>
    <key>CFBundleDisplayName</key><string>Touch Bar 亮度</string>
    <key>CFBundleIdentifier</key><string>com.dem0ns.TouchBarBrightness</string>
    <key>CFBundleExecutable</key><string>TouchBarBrightness</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true

echo "==> done"
echo "    CLI : $(pwd)/bin/tbright"
echo "    App : $(pwd)/$APP"

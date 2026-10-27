#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# ARCH_FLAGS lets CI produce a universal binary:
#   ARCH_FLAGS="-arch arm64 -arch x86_64" ./build.sh
ARCH_FLAGS="${ARCH_FLAGS:-}"
MIN_FLAGS="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET:-11.0}"
CFLAGS=($ARCH_FLAGS $MIN_FLAGS -fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter)

mkdir -p bin

echo "==> building CLI"
clang "${CFLAGS[@]}" -framework Foundation \
    -o bin/tbright src/tbright.m src/TBCore.m

echo "==> building menu bar app"
APP="bin/TouchBarBrightness.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

clang "${CFLAGS[@]}" -framework Cocoa -framework Foundation \
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
    <key>CFBundleShortVersionString</key><string>__VERSION__</string>
    <key>CFBundleVersion</key><string>__BUILD__</string>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

VERSION="${VERSION:-0.0.0}"
BUILD="${BUILD:-1}"
sed -i '' "s/__VERSION__/$VERSION/; s/__BUILD__/$BUILD/" "$APP/Contents/Info.plist"

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
codesign --force --sign - bin/tbright >/dev/null 2>&1 || true

echo "==> done (version $VERSION)"
echo "    CLI : $(pwd)/bin/tbright"
echo "    App : $(pwd)/$APP"

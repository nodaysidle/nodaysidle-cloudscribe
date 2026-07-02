#!/bin/bash
# package_app.sh — Build and package CloudScribe.app for distribution
# Adapted from ShareGuard packaging pattern.
#
# Usage: ./Scripts/package_app.sh [--debug|--release]
# Output: .build/release/CloudScribe.app by default

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CONFIG="release"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release) CONFIG="release"; shift ;;
        --debug) CONFIG="debug"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "=== CloudScribe: Packaging ($CONFIG) ==="

if [ "$CONFIG" = "release" ]; then
    swift build -c release -Xswiftc -strict-concurrency=complete
    BIN_DIR=".build/arm64-apple-macosx/release"
else
    swift build -Xswiftc -strict-concurrency=complete
    BIN_DIR=".build/arm64-apple-macosx/debug"
fi

EXECUTABLE="$BIN_DIR/CloudScribe"
if [ ! -f "$EXECUTABLE" ]; then
    EXECUTABLE=".build/$CONFIG/CloudScribe"
fi
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Executable not found"
    exit 1
fi

APP_DIR=".build/$CONFIG/CloudScribe.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/CloudScribe"
chmod +x "$APP_DIR/Contents/MacOS/CloudScribe"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>CloudScribe</string>
    <key>CFBundleExecutable</key>
    <string>CloudScribe</string>
    <key>CFBundleIdentifier</key>
    <string>com.nodaysidle.cloudscribe</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CloudScribe</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.3.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>CloudScribe needs microphone access to capture audio for cloud speech-to-text transcription.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

ICON_SVG="$REPO_ROOT/Resources/CloudScribe-icon.svg"
ICNS_OUT="$APP_DIR/Contents/Resources/AppIcon.icns"
if command -v rsvg-convert &> /dev/null && command -v iconutil &> /dev/null && [ -f "$ICON_SVG" ]; then
    echo "--- Generating app icon from SVG ---"
    ICONSET=".build/cloudscribe.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    ICON_OK=true
    for size in 16 32 64 128 256 512; do
        rsvg-convert -w "$size" -h "$size" "$ICON_SVG" -o "$ICONSET/icon_${size}x${size}.png" 2>/dev/null || ICON_OK=false
        rsvg-convert -w "$((size*2))" -h "$((size*2))" "$ICON_SVG" -o "$ICONSET/icon_${size}x${size}@2x.png" 2>/dev/null || ICON_OK=false
    done
    if $ICON_OK; then
        iconutil -c icns "$ICONSET" -o "$ICNS_OUT" 2>/dev/null && echo "--- Icon generated ---" || echo "--- Icon generation skipped: iconutil rejected generated iconset ---"
        rsvg-convert -w 18 -h 18 "$ICON_SVG" -o "$APP_DIR/Contents/Resources/MenuBarIcon.png" 2>/dev/null && echo "--- Menu bar icon generated ---" || echo "--- Menu bar icon skipped ---"
    else
        echo "--- Icon generation skipped: rsvg-convert failed ---"
    fi
    rm -rf "$ICONSET"
else
    echo "--- Skipping icon generation (rsvg-convert and/or iconutil unavailable, or SVG missing) ---"
fi

ENTITLEMENTS="$REPO_ROOT/Resources/CloudScribe.entitlements"
if [ ! -f "$ENTITLEMENTS" ]; then
    echo "ERROR: Missing entitlements at $ENTITLEMENTS"
    exit 1
fi

echo "--- Ad-hoc signing (hardened runtime + audio-input entitlement) ---"
codesign --force --deep --sign - --options runtime --entitlements "$ENTITLEMENTS" "$APP_DIR"

echo "--- Verifying bundle ---"
test -x "$APP_DIR/Contents/MacOS/CloudScribe"
test -f "$APP_DIR/Contents/Info.plist"
test "$(xxd -p "$APP_DIR/Contents/PkgInfo")" = "4150504c3f3f3f3f"
codesign --verify --deep --strict "$APP_DIR"

echo ""
echo "=== Package complete: $APP_DIR ==="
echo "Run: open $APP_DIR"

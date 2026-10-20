#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_NAME="AndroMac.app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"

echo "=== Building AndroMac macOS Application (Optimized Release) ==="

cd "$PROJECT_ROOT"
swift build -c release -Xswiftc -O -Xswiftc -whole-module-optimization

echo "=== Creating macOS .app Bundle Structure ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$PROJECT_ROOT/.build/release/AndroMac" "$APP_BUNDLE/Contents/MacOS/AndroMac"
cp "$PROJECT_ROOT/Sources/AndroMac/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$PROJECT_ROOT/Sources/AndroMac/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Sources/AndroMac/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

chmod +x "$APP_BUNDLE/Contents/MacOS/AndroMac"

echo "=== Stripping Debug Symbols for Maximum Launch Speed ==="
strip -u -r "$APP_BUNDLE/Contents/MacOS/AndroMac" 2>/dev/null || true

echo "=== Code Signing Bundle (Ad-Hoc Development) ==="
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Verification ==="
codesign --verify --deep --strict "$APP_BUNDLE"
echo "✅ Successfully built: $APP_BUNDLE"
ls -la "$APP_BUNDLE/Contents"

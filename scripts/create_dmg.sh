#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_BUNDLE="$BUILD_DIR/AndroMac.app"
DMG_NAME="AndroMac-1.4.2-AppleSilicon.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
DMG_STAGING="$BUILD_DIR/dmg_staging"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE does not exist. Run scripts/build_app.sh first."
    exit 1
fi

echo "=== Creating macOS DMG Installer ==="
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"

# Copy App to staging
cp -R "$APP_BUNDLE" "$DMG_STAGING/"

# Create /Applications symlink for drag-and-drop installer
ln -s /Applications "$DMG_STAGING/Applications"

# Create compressed DMG image
hdiutil create -volname "AndroMac Installer" \
               -srcfolder "$DMG_STAGING" \
               -ov \
               -format UDZO \
               "$DMG_PATH"

rm -rf "$DMG_STAGING"

echo "✅ Successfully generated DMG: $DMG_PATH"
ls -lh "$DMG_PATH"

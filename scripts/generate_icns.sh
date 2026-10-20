#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_to_1024x1024_png> [output_icns_path]"
    exit 1
fi

INPUT_PNG="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_ICNS="${2:-$PROJECT_ROOT/Sources/AndroMac/Resources/AppIcon.icns}"
ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"

mkdir -p "$ICONSET_DIR"

echo "=== Generating macOS Iconset from $INPUT_PNG ==="

sips -z 16 16     "$INPUT_PNG" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     "$INPUT_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$INPUT_PNG" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     "$INPUT_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$INPUT_PNG" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   "$INPUT_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$INPUT_PNG" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   "$INPUT_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$INPUT_PNG" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 "$INPUT_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "=== Compiling to .icns with iconutil ==="
mkdir -p "$(dirname "$OUTPUT_ICNS")"
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

# Also update documentation asset (512x512 PNG)
mkdir -p "$PROJECT_ROOT/docs/assets"
sips -z 512 512 "$INPUT_PNG" --out "$PROJECT_ROOT/docs/assets/icon.png" > /dev/null

rm -rf "$(dirname "$ICONSET_DIR")"
echo "✅ Successfully generated: $OUTPUT_ICNS"
echo "✅ Successfully updated: $PROJECT_ROOT/docs/assets/icon.png"

#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/build"
APP_DIR="$BUILD_DIR/Keyviz.app"
CONTENTS_DIR="$APP_DIR/Contents"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

cd "$ROOT"
swift build -c release

rm -rf "$APP_DIR" "$ICONSET_DIR"
mkdir -p "$CONTENTS_DIR/MacOS" "$CONTENTS_DIR/Resources" "$ICONSET_DIR"

cp ".build/release/Keyviz" "$CONTENTS_DIR/MacOS/Keyviz"
cp "App/Info.plist" "$CONTENTS_DIR/Info.plist"

for size in 16 32 128 256 512; do
    sips -s format png -z "$size" "$size" "Resources/AppIcon.svg" \
        --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -s format png -z "$double_size" "$double_size" "Resources/AppIcon.svg" \
        --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$CONTENTS_DIR/Resources/AppIcon.icns"
rm -rf "$ICONSET_DIR"

codesign --force --deep --sign - "$APP_DIR"
echo "Built $APP_DIR"

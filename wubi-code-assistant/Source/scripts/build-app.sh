#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT/output}"
CACHE_DIR="$ROOT/.cache"
BUILD_STAGE="$(mktemp -d)"
APP_STAGE="$BUILD_STAGE/Wubi Code Assistant.app"
ICONSET="$BUILD_STAGE/AppIcon.iconset"

cleanup() {
    rm -rf "$BUILD_STAGE"
}
trap cleanup EXIT

mkdir -p "$CACHE_DIR/clang" "$CACHE_DIR/swiftpm" "$OUTPUT_DIR"

env \
    CLANG_MODULE_CACHE_PATH="$CACHE_DIR/clang" \
    SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_DIR/swiftpm" \
    swift build --disable-sandbox -c release --arch arm64 --arch x86_64 --package-path "$ROOT"
BIN_DIR="$(swift build --disable-sandbox -c release --arch arm64 --arch x86_64 --package-path "$ROOT" --show-bin-path)"

mkdir -p "$APP_STAGE/Contents/MacOS" "$APP_STAGE/Contents/Resources" "$ICONSET"
cp "$BIN_DIR/RimeWubiAssistant" "$APP_STAGE/Contents/MacOS/RimeWubiAssistant"
cp "$ROOT/Resources/Info.plist" "$APP_STAGE/Contents/Info.plist"
ditto "$ROOT/Resources/Decomposition" "$APP_STAGE/Contents/Resources/Decomposition"
ditto "$ROOT/Resources/ThirdParty" "$APP_STAGE/Contents/Resources/ThirdParty"
ditto "$BIN_DIR/RimeWubiAssistant_RimeWubiCore.bundle" "$APP_STAGE/Contents/Resources/RimeWubiAssistant_RimeWubiCore.bundle"
cp "$ROOT/../NOTICE.md" "$APP_STAGE/Contents/Resources/ThirdParty/NOTICE.md"
cp "$ROOT/../LICENSE" "$APP_STAGE/Contents/Resources/ThirdParty/GPL-3.0.txt"

sips -z 16 16 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$ROOT/Resources/AppIcon-1024.png" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
env \
    CLANG_MODULE_CACHE_PATH="$CACHE_DIR/clang" \
    SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_DIR/swiftpm" \
    xcrun swift "$ROOT/scripts/make-icns.swift" "$ICONSET" "$APP_STAGE/Contents/Resources/AppIcon.icns"

chmod 755 "$APP_STAGE/Contents/MacOS/RimeWubiAssistant"
codesign --force --sign - "$APP_STAGE"
ditto "$APP_STAGE" "$OUTPUT_DIR/Wubi Code Assistant.app"

echo "$OUTPUT_DIR/Wubi Code Assistant.app"

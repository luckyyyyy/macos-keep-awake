#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
APP_DIR="$BUILD_DIR/KeepAwake.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE="$BUILD_DIR/module-cache"
ARM_BINARY="$BUILD_DIR/KeepAwake-arm64"
INTEL_BINARY="$BUILD_DIR/KeepAwake-x86_64"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE"

COMMON_ARGS=(
  -swift-version 5
  -O
  -module-cache-path "$MODULE_CACHE"
  -framework AppKit
  -framework IOKit
  "$PROJECT_ROOT/KeepAwake.swift"
)

xcrun swiftc -target arm64-apple-macosx12.0 "${COMMON_ARGS[@]}" -o "$ARM_BINARY"
xcrun swiftc -target x86_64-apple-macosx12.0 "${COMMON_ARGS[@]}" -o "$INTEL_BINARY"

lipo -create "$ARM_BINARY" "$INTEL_BINARY" -output "$MACOS_DIR/KeepAwake"
cp "$PROJECT_ROOT/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
plutil -lint "$CONTENTS_DIR/Info.plist"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Built: $APP_DIR"

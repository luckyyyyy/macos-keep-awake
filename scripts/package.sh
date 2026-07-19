#!/bin/bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$PROJECT_ROOT/build/KeepAwake.app"
DIST_DIR="$PROJECT_ROOT/dist"
ARCHIVE="$DIST_DIR/KeepAwake-macOS-universal.zip"

"$PROJECT_ROOT/scripts/build.sh"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE"

echo "Packaged: $ARCHIVE"

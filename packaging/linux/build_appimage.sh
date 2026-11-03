#!/usr/bin/env bash
# Builds AssetDeck-x86_64.AppImage from the PyInstaller output in dist/assetdeck.
# Usage (from the repository root, after `pyinstaller packaging/assetdeck.spec`):
#   packaging/linux/build_appimage.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

APPIMAGETOOL_VERSION="1.9.1"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-x86_64.AppImage"

DIST_DIR="$ROOT/dist/assetdeck"
BUILD_DIR="$ROOT/build/appimage"
APPDIR="$BUILD_DIR/AppDir"
TOOL="$BUILD_DIR/appimagetool-${APPIMAGETOOL_VERSION}-x86_64.AppImage"
ICON="$ROOT/assetdeck/ui/icons/app-icon.png"
OUTPUT="${OUTPUT:-$ROOT/AssetDeck-x86_64.AppImage}"

if [ ! -x "$DIST_DIR/assetdeck" ]; then
    echo "PyInstaller output not found at $DIST_DIR — run: pyinstaller packaging/assetdeck.spec" >&2
    exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -a "$DIST_DIR" "$APPDIR/usr/bin/assetdeck"
install -m 0755 "$ROOT/packaging/linux/AppRun" "$APPDIR/AppRun"
install -m 0644 "$ROOT/packaging/linux/assetdeck.desktop" "$APPDIR/assetdeck.desktop"
install -m 0644 "$ROOT/packaging/linux/assetdeck.desktop" "$APPDIR/usr/share/applications/assetdeck.desktop"
install -m 0644 "$ICON" "$APPDIR/assetdeck.png"
install -m 0644 "$ICON" "$APPDIR/usr/share/icons/hicolor/256x256/apps/assetdeck.png"
ln -sf assetdeck.png "$APPDIR/.DirIcon"

if [ ! -f "$TOOL" ]; then
    echo "Downloading appimagetool ${APPIMAGETOOL_VERSION}..."
    curl -fsSL -o "$TOOL.part" "$APPIMAGETOOL_URL"
    mv "$TOOL.part" "$TOOL"
fi
echo "${APPIMAGETOOL_SHA256}  ${TOOL}" | sha256sum -c -
chmod +x "$TOOL"

TOOL_ARGS=()
if [ ! -e /dev/fuse ] || { ! command -v fusermount >/dev/null 2>&1 && ! command -v fusermount3 >/dev/null 2>&1; }; then
    TOOL_ARGS+=(--appimage-extract-and-run)
fi

rm -f "$OUTPUT"
ARCH=x86_64 "$TOOL" ${TOOL_ARGS[@]+"${TOOL_ARGS[@]}"} --no-appstream "$APPDIR" "$OUTPUT"
chmod +x "$OUTPUT"
echo "Built $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"

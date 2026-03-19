#!/usr/bin/env bash
# Update Android and iOS app icons from an easyappicon-style folder.
#
# Usage:
#   ./scripts/update_icons.sh <path-to-easyappicon-folder>
#
# Example:
#   ./scripts/update_icons.sh ~/Desktop/easyappicon-icons-1773507672873
#
# Folder structure expected (same as easyappicon output):
#   android/
#     mipmap-ldpi/
#     mipmap-mdpi/
#     mipmap-hdpi/
#     mipmap-xhdpi/
#     mipmap-xxhdpi/
#     mipmap-xxxhdpi/
#     mipmap-anydpi-v26/
#     values/
#       ic_launcher_background.xml
#   ios/
#     AppIcon.appiconset/
#       Contents.json
#       Icon-App-*.png
#       ItunesArtwork@2x.png

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <path-to-easyappicon-folder>"
  echo "Example: $0 ~/Desktop/easyappicon-icons-1773507672873"
  exit 1
fi

ICON_SRC="$(cd "$1" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RES="$PROJECT_ROOT/android/app/src/main/res"
IOS_ICONS="$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"

if [ ! -d "$ICON_SRC/android" ] || [ ! -d "$ICON_SRC/ios" ]; then
  echo "Error: Source folder must contain 'android' and 'ios' directories."
  echo "  Got: $ICON_SRC"
  exit 1
fi

echo "Source: $ICON_SRC"
echo "Project: $PROJECT_ROOT"
echo ""

# --- Android ---
echo "Updating Android icons..."
for d in mipmap-ldpi mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
  if [ -d "$ICON_SRC/android/$d" ]; then
    mkdir -p "$RES/$d"
    cp -f "$ICON_SRC/android/$d"/*.png "$RES/$d/" 2>/dev/null || true
    echo "  $d"
  fi
done
if [ -d "$ICON_SRC/android/mipmap-anydpi-v26" ]; then
  mkdir -p "$RES/mipmap-anydpi-v26"
  cp -f "$ICON_SRC/android/mipmap-anydpi-v26"/*.xml "$RES/mipmap-anydpi-v26/"
  echo "  mipmap-anydpi-v26"
fi
if [ -f "$ICON_SRC/android/values/ic_launcher_background.xml" ]; then
  cp -f "$ICON_SRC/android/values/ic_launcher_background.xml" "$RES/values/"
  echo "  values/ic_launcher_background.xml"
fi
echo "Android done."
echo ""

# --- iOS ---
echo "Updating iOS AppIcon..."
if [ -f "$ICON_SRC/ios/AppIcon.appiconset/Contents.json" ]; then
  rm -f "$IOS_ICONS"/*.png
  cp -f "$ICON_SRC/ios/AppIcon.appiconset/Contents.json" "$IOS_ICONS/"
  cp -f "$ICON_SRC/ios/AppIcon.appiconset"/*.png "$IOS_ICONS/" 2>/dev/null || true
  echo "  AppIcon.appiconset (Contents.json + PNGs)"
else
  echo "  Skipped: no Contents.json in source AppIcon.appiconset"
fi
echo "iOS done."
echo ""
echo "Icons updated. Rebuild the app to see changes."

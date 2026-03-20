#!/usr/bin/env bash
# Update Android, iOS, and macOS app icons from an easyappicon-style folder
# or from a single 1024×1024 PNG (macOS only, auto-resized via sips).
#
# Usage:
#   ./scripts/update_icons.sh <path-to-easyappicon-folder>
#   ./scripts/update_icons.sh <path-to-easyappicon-folder> --macos-icon <path-to-1024px.png>
#
# Examples:
#   ./scripts/update_icons.sh ~/Desktop/easyappicon-icons-1773507672873
#   ./scripts/update_icons.sh ~/Desktop/easyappicon-icons-1773507672873 --macos-icon ~/Desktop/icon1024.png
#
# Folder structure expected (same as easyappicon output):
#   android/
#     mipmap-ldpi/  mipmap-mdpi/  mipmap-hdpi/
#     mipmap-xhdpi/  mipmap-xxhdpi/  mipmap-xxxhdpi/
#     mipmap-anydpi-v26/
#     values/ic_launcher_background.xml
#   ios/
#     AppIcon.appiconset/
#       Contents.json + Icon-App-*.png
#   macos/                          ← optional; auto-generated if absent
#     AppIcon.appiconset/
#       app_icon_16.png  app_icon_32.png  app_icon_64.png
#       app_icon_128.png  app_icon_256.png  app_icon_512.png
#       app_icon_1024.png  Contents.json

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <path-to-easyappicon-folder> [--macos-icon <1024px.png>]"
  exit 1
fi

ICON_SRC="$(cd "$1" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RES="$PROJECT_ROOT/android/app/src/main/res"
IOS_ICONS="$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
MACOS_ICONS="$PROJECT_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset"

# Optional --macos-icon override
MACOS_SINGLE_PNG=""
while [[ $# -gt 1 ]]; do
  case "$2" in
    --macos-icon)
      MACOS_SINGLE_PNG="$3"
      shift 2
      ;;
    *) shift ;;
  esac
done

if [ ! -d "$ICON_SRC/android" ] || [ ! -d "$ICON_SRC/ios" ]; then
  echo "Error: Source folder must contain 'android' and 'ios' directories."
  echo "  Got: $ICON_SRC"
  exit 1
fi

echo "Source : $ICON_SRC"
echo "Project: $PROJECT_ROOT"
echo ""

# ── Android ───────────────────────────────────────────────────────────────────
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

# ── iOS ───────────────────────────────────────────────────────────────────────
echo "Updating iOS AppIcon..."
if [ -f "$ICON_SRC/ios/AppIcon.appiconset/Contents.json" ]; then
  rm -f "$IOS_ICONS"/*.png
  cp -f "$ICON_SRC/ios/AppIcon.appiconset/Contents.json" "$IOS_ICONS/"
  cp -f "$ICON_SRC/ios/AppIcon.appiconset"/*.png "$IOS_ICONS/" 2>/dev/null || true
  echo "  AppIcon.appiconset (Contents.json + PNGs)"
else
  echo "  Skipped: no Contents.json in source ios/AppIcon.appiconset"
fi
echo "iOS done."
echo ""

# ── macOS ─────────────────────────────────────────────────────────────────────
echo "Updating macOS AppIcon..."
mkdir -p "$MACOS_ICONS"

# Determine source: prefer pre-built appiconset, then --macos-icon PNG,
# then fall back to the largest iOS icon as a base image.
MACOS_APPICONSET="$ICON_SRC/macos/AppIcon.appiconset"

if [ -f "$MACOS_APPICONSET/app_icon_1024.png" ]; then
  # ── Path A: easyappicon provided a macos/ folder ──────────────────────────
  rm -f "$MACOS_ICONS"/*.png
  cp -f "$MACOS_APPICONSET"/*.png "$MACOS_ICONS/"
  # Copy Contents.json only if provided; otherwise keep the existing one.
  if [ -f "$MACOS_APPICONSET/Contents.json" ]; then
    cp -f "$MACOS_APPICONSET/Contents.json" "$MACOS_ICONS/"
  fi
  echo "  Copied from macos/AppIcon.appiconset"

else
  # ── Path B: generate from a single PNG via sips ───────────────────────────
  # Resolve the base image: --macos-icon arg > ios 1024px > ios largest available
  if [ -n "$MACOS_SINGLE_PNG" ]; then
    BASE_PNG="$MACOS_SINGLE_PNG"
  elif [ -f "$ICON_SRC/ios/AppIcon.appiconset/ItunesArtwork@2x.png" ]; then
    BASE_PNG="$ICON_SRC/ios/AppIcon.appiconset/ItunesArtwork@2x.png"
  else
    # Pick the largest PNG in the iOS appiconset as fallback
    BASE_PNG=$(ls -S "$ICON_SRC/ios/AppIcon.appiconset"/*.png 2>/dev/null | head -1)
  fi

  if [ -z "$BASE_PNG" ] || [ ! -f "$BASE_PNG" ]; then
    echo "  Skipped: no macOS source found."
    echo "  Provide a macos/AppIcon.appiconset/ in the source folder,"
    echo "  or pass --macos-icon <1024px.png>"
  else
    echo "  Generating from: $BASE_PNG"
    rm -f "$MACOS_ICONS"/app_icon_*.png

    # macOS requires these exact sizes (points × scale = pixels):
    #   16×1x=16  16×2x=32  32×1x=32  32×2x=64
    #   128×1x=128  128×2x=256  256×1x=256  256×2x=512
    #   512×1x=512  512×2x=1024
    declare -a SIZES=(16 32 64 128 256 512 1024)
    for SIZE in "${SIZES[@]}"; do
      OUT="$MACOS_ICONS/app_icon_${SIZE}.png"
      sips -z "$SIZE" "$SIZE" "$BASE_PNG" --out "$OUT" > /dev/null
      echo "    app_icon_${SIZE}.png"
    done
  fi
fi

echo "macOS done."
echo ""
echo "Icons updated. Rebuild the app to see changes."

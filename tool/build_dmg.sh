#!/usr/bin/env bash
set -e

# Resolve project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🚀 Building Mole GUI Release App..."
cd "${PROJECT_ROOT}"
flutter build macos --release

APP_PATH="${PROJECT_ROOT}/build/macos/Build/Products/Release/Mole GUI.app"
DIST_DIR="${PROJECT_ROOT}/dist"
OUTPUT_DMG="${DIST_DIR}/Mole-GUI.dmg"
ICONSET_DIR="${PROJECT_ROOT}/build/MoleGUI.iconset"
ICNS_PATH="${PROJECT_ROOT}/build/MoleGUI.icns"

mkdir -p "${DIST_DIR}"
mkdir -p "${ICONSET_DIR}"

echo "🎨 Generating volume icon..."
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png "${ICONSET_DIR}/icon_16x16.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png "${ICONSET_DIR}/icon_16x16@2x.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png "${ICONSET_DIR}/icon_32x32.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png "${ICONSET_DIR}/icon_32x32@2x.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png "${ICONSET_DIR}/icon_128x128.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png "${ICONSET_DIR}/icon_128x128@2x.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png "${ICONSET_DIR}/icon_256x256.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png "${ICONSET_DIR}/icon_256x256@2x.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png "${ICONSET_DIR}/icon_512x512.png"
cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png "${ICONSET_DIR}/icon_512x512@2x.png"

iconutil -c icns "${ICONSET_DIR}" -o "${ICNS_PATH}"

echo "📦 Creating fancy DMG installer with Applications drag-and-drop link..."
create-dmg \
  --volname "Mole GUI" \
  --volicon "${ICNS_PATH}" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 128 \
  --text-size 14 \
  --icon "Mole GUI.app" 180 180 \
  --hide-extension "Mole GUI.app" \
  --app-drop-link 480 180 \
  --overwrite \
  "${OUTPUT_DMG}" \
  "${APP_PATH}"

echo "✅ DMG successfully built at: ${OUTPUT_DMG}"

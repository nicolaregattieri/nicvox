#!/bin/bash

# Ensure we are in the script's directory
cd "$(dirname "$0")"

APP_NAME="NicVox"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}_Installer.dmg"
VOL_NAME="${APP_NAME} Installer"

echo "📦 Preparing to package $APP_NAME..."

# Check if App exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ Error: App not found in $BUILD_DIR. Please run ./install.sh first."
    exit 1
fi

# Clean previous DMG
rm -f "$DMG_NAME"

# Create a temporary folder for the DMG content
mkdir -p "dist"
cp -r "$BUILD_DIR/$APP_NAME.app" "dist/"
ln -s /Applications "dist/Applications"

echo "💿 Creating DMG..."
hdiutil create -volname "$VOL_NAME" -srcfolder "dist" -ov -format UDZO "$DMG_NAME"

# Cleanup
rm -rf "dist"

echo "✅ DMG Created: $DMG_NAME"
echo "🚀 Send this file to your friends!"

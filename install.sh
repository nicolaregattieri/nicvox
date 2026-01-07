#!/bin/bash

# Ensure we are in the script's directory
cd "$(dirname "$0")"

APP_NAME="NicVox"
BUILD_DIR="build"
SOURCES="Sources/main.swift Sources/AppDelegate.swift Sources/SpeechManager.swift Sources/HotKeyManager.swift Sources/SettingsView.swift Sources/KeyCodeMap.swift"

echo "🧹 Cleaning up..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

ARCH=$(uname -m)
echo "🖥️  Detected architecture: $ARCH"

echo "🔨 Compiling..."
swiftc $SOURCES -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" -target $ARCH-apple-macosx12.0 -framework Cocoa -framework Speech -framework AVFoundation -framework Carbon

echo "🎨 Generating App Icon..."
if [ -f "nvx.png" ]; then
    ICONSET="AppIcon.iconset"
    mkdir -p $ICONSET

    # Generate standard sizes
    sips -z 16 16     nvx.png --out "${ICONSET}/icon_16x16.png" > /dev/null
    sips -z 32 32     nvx.png --out "${ICONSET}/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     nvx.png --out "${ICONSET}/icon_32x32.png" > /dev/null
    sips -z 64 64     nvx.png --out "${ICONSET}/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   nvx.png --out "${ICONSET}/icon_128x128.png" > /dev/null
    sips -z 256 256   nvx.png --out "${ICONSET}/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   nvx.png --out "${ICONSET}/icon_256x256.png" > /dev/null
    sips -z 512 512   nvx.png --out "${ICONSET}/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   nvx.png --out "${ICONSET}/icon_512x512.png" > /dev/null
    sips -z 1024 1024 nvx.png --out "${ICONSET}/icon_512x512@2x.png" > /dev/null

    # Convert to icns
    iconutil -c icns $ICONSET
    
    # Move to Resources
    cp AppIcon.icns "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
    
    # Cleanup
    rm -rf $ICONSET
    rm AppIcon.icns
    echo "✅ Icon created."
else
    echo "⚠️ nvx.png not found, skipping icon generation."
fi

echo "📄 Copying Info.plist..."
cp Info.plist "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"

echo "✅ Build complete!"
echo "👉 You can run the app from: $BUILD_DIR/$APP_NAME.app"
echo "   Or move it to Applications: mv $BUILD_DIR/$APP_NAME.app /Applications/"

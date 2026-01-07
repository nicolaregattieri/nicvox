#!/bin/bash

APP_NAME="NicVox"
BUILD_DIR="build"
# Include ALL source files
SOURCES="Sources/main.swift Sources/AppDelegate.swift Sources/SpeechManager.swift Sources/HotKeyManager.swift Sources/SettingsView.swift Sources/KeyCodeMap.swift Sources/Logger.swift"

echo "🧹 Cleaning up..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

ARCH=$(uname -m)
echo "🖥️  Detected architecture: $ARCH"

echo "🔨 Compiling NicVox..."
swiftc $SOURCES -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -target $ARCH-apple-macosx12.0 \
    -framework Cocoa -framework Speech -framework AVFoundation -framework Carbon \
    -O -D RELEASE # Optimized build without debug prints

echo "🎨 Generating App Icon..."
if [ -f "nvx.png" ]; then
    ICONSET="AppIcon.iconset"
    mkdir -p $ICONSET
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
    iconutil -c icns $ICONSET
    cp AppIcon.icns "$BUILD_DIR/$APP_NAME.app/Contents/Resources/"
    rm -rf $ICONSET
    rm AppIcon.icns
fi

echo "📄 Copying Info.plist..."
cp Info.plist "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"

echo "✅ Build complete!"

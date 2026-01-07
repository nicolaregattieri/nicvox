#!/bin/bash

APP_NAME="NicVox"
INSTALL_DIR="/Applications"
TEMP_DIR=$(mktemp -d)
REPO_URL="https://github.com/nicolaregattieri/NicVox"

echo "🟣 Installing $APP_NAME..."

# 1. Try to download pre-built binary (Best experience)
# Note: You need to create a Release on GitHub and attach NicVox.zip for this to work perfectly.
echo "⬇️  Attempting to download latest release..."
LATEST_URL="$REPO_URL/releases/latest/download/$APP_NAME.zip"

if curl --output /dev/null --silent --head --fail "$LATEST_URL"; then
    curl -L -o "$TEMP_DIR/$APP_NAME.zip" "$LATEST_URL"
    unzip -q "$TEMP_DIR/$APP_NAME.zip" -d "$TEMP_DIR"
    
    echo "📦 Moving to Applications..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    mv "$TEMP_DIR/$APP_NAME.app" "$INSTALL_DIR/"
    
    echo "✅ Installed successfully from Release!"
else
    echo "⚠️  Release not found. Building from source... (Requires Swift)"
    
    # 2. Fallback: Build from source
    if ! command -v swiftc &> /dev/null; then
        echo "❌ Error: Swift compiler not found. Please install Xcode Command Line Tools or download the App manually."
        exit 1
    fi
    
    git clone --depth 1 $REPO_URL "$TEMP_DIR/source"
    cd "$TEMP_DIR/source"
    ./install.sh
    
    # install.sh already moves to build/, let's move to Applications
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    mv "build/$APP_NAME.app" "$INSTALL_DIR/"
    
    echo "✅ Built and Installed successfully!"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "🎉 NicVox is ready! You can open it from your Applications folder."
open "$INSTALL_DIR/$APP_NAME.app"

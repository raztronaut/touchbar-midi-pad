#!/bin/bash

# Exit on error
set -e

APP_NAME="Sleek"
SCHEME_NAME="Sleek"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}_Installer.dmg"

echo "🚀 Starting build process for $APP_NAME..."


# Check if App already exists
APP_PATH=$(find "$BUILD_DIR/Build/Products/Release" -name "$APP_NAME.app" | head -n 1)

if [ -d "$APP_PATH" ]; then
    read -p "❓ App found at $APP_PATH. Rebuild? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "⏭️  Skipping build..."
        SKIP_BUILD=true
    fi
fi

if [ "$SKIP_BUILD" != "true" ]; then
    # 1. Clean previous build
    echo "🧹 Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    rm -f "$DMG_NAME"

    # 2. Build the app using xcodebuild
    echo "🔨 Building $APP_NAME (Release)..."
    xcodebuild -scheme "$SCHEME_NAME" \
               -configuration Release \
               -derivedDataPath "$BUILD_DIR" \
               -destination 'platform=macOS' \
               clean build \
               | xcbeautify || echo "Note: Install xcbeautify for prettier logs (brew install xcbeautify)"
               
    # Re-locate after build
    APP_PATH=$(find "$BUILD_DIR/Build/Products/Release" -name "$APP_NAME.app" | head -n 1)
fi

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built app."
    exit 1
fi

echo "✅ App ready at: $APP_PATH"

# 3. Create a temporary directory for DMG contents
echo "📦 Preparing DMG contents..."
DMG_ROOT="dmg_root"
rm -rf "$DMG_ROOT" # Ensure clean state
mkdir -p "$DMG_ROOT"

# Copy the app to the DMG root
cp -R "$APP_PATH" "$DMG_ROOT/"

# Create a symlink to /Applications
ln -s /Applications "$DMG_ROOT/Applications"

# 4. Create the DMG
echo "💿 Creating compiled DMG..."
# Check if old DMG exists and remove
rm -f "$DMG_NAME"

hdiutil create -volname "$APP_NAME Installer" \
               -srcfolder "$DMG_ROOT" \
               -ov -format UDZO \
               "$DMG_NAME"

# 5. Cleanup

# 5. Cleanup
echo "🧹 Cleaning up temporary files..."
rm -rf "$DMG_ROOT"

echo "🎉 Done! DMG created at: $(pwd)/$DMG_NAME"

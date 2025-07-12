#!/bin/bash
cd AdGuardDNSController
swift build --configuration release

# Create .app bundle
cd ..
APP_NAME="AdGuard DNS Toggle.app"
CONTENTS_DIR="$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Create directory structure
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy executable
cp AdGuardDNSController/.build/release/AdGuardDNSController "$MACOS_DIR/AdGuard DNS Toggle"

# Copy icon and Info.plist
cp AdGuardDNSController/Resources/AdGuardIcon.icns "$RESOURCES_DIR/"
cp AdGuardDNSController/Resources/Info.plist "$CONTENTS_DIR/"

echo "App bundle created: $APP_NAME"

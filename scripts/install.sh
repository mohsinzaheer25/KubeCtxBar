#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       KubeCtx Installer                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check for required tools
echo -e "${YELLOW}Checking requirements...${NC}"

if ! command -v swift &> /dev/null; then
    echo -e "${RED}Error: Swift is not installed. Please install Xcode Command Line Tools.${NC}"
    echo "Run: xcode-select --install"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All requirements met${NC}"
echo ""

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if we're in the project directory or need to clone
if [[ -f "$PROJECT_ROOT/Package.swift" ]]; then
    echo -e "${YELLOW}Building from local source...${NC}"
    cd "$PROJECT_ROOT"
else
    # Clone the repository
    echo -e "${YELLOW}Cloning KubeCtxBar...${NC}"
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/mohsinzaheer25/KubeCtxBar.git
    cd KubeCtxBar
    PROJECT_ROOT="$TEMP_DIR/KubeCtxBar"
fi

# Build release
echo ""
echo -e "${YELLOW}Building release...${NC}"
swift build -c release

# Create app bundle
echo ""
echo -e "${YELLOW}Creating app bundle...${NC}"

APP_NAME="KubeCtx"
APP_BUNDLE="$PROJECT_ROOT/$APP_NAME.app"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$PROJECT_ROOT/.build/release/KubeCtxBar" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.kubectx.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copy icon if exists
if [[ -f "$PROJECT_ROOT/AppIcon.icns" ]]; then
    cp "$PROJECT_ROOT/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# Sign the app
echo ""
echo -e "${YELLOW}Signing app...${NC}"
codesign --force --sign - "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
codesign --force --sign - "$APP_BUNDLE"

# Install to Applications
echo ""
echo -e "${YELLOW}Installing to /Applications...${NC}"

if [[ -d "/Applications/$APP_NAME.app" ]]; then
    echo -e "${YELLOW}Removing existing installation...${NC}"
    rm -rf "/Applications/$APP_NAME.app"
fi

cp -r "$APP_BUNDLE" "/Applications/"
xattr -cr "/Applications/$APP_NAME.app"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Installation Complete!           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "KubeCtx has been installed to ${GREEN}/Applications/KubeCtx.app${NC}"
echo ""
echo -e "${YELLOW}To start KubeCtx:${NC}"
echo "  open /Applications/KubeCtx.app"
echo ""
echo -e "${YELLOW}To enable Launch at Login:${NC}"
echo "  1. Click the KubeCtx icon in the menu bar"
echo "  2. Go to Settings"
echo "  3. Enable 'Launch at Login'"
echo ""

# Ask to launch
read -p "Would you like to launch KubeCtx now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "/Applications/$APP_NAME.app"
    echo -e "${GREEN}KubeCtx is now running in your menu bar!${NC}"
fi

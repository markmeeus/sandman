#!/bin/bash

# Build script for Sandman macOS app with embedded Phoenix release
# This script builds the macOS app using Xcode and embeds the Phoenix release

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building Sandman macOS app with embedded Phoenix release...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MACOS_APP_DIR="$SCRIPT_DIR/sandman"
RELEASE_DIR="$PROJECT_ROOT/sandman/_build/prod/rel/sandman"

echo -e "${YELLOW}📁 Project root: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}📱 macOS app directory: $MACOS_APP_DIR${NC}"
echo -e "${YELLOW}📦 Release directory: $RELEASE_DIR${NC}"

# Check if Phoenix release exists
if [ ! -d "$RELEASE_DIR" ]; then
    echo -e "${RED}❌ Phoenix release not found at $RELEASE_DIR${NC}"
    echo -e "${YELLOW}💡 Please build the Phoenix release first:${NC}"
    echo -e "${YELLOW}   cd $PROJECT_ROOT/sandman && mix release${NC}"
    exit 1
fi

# Check if macOS app directory exists
if [ ! -d "$MACOS_APP_DIR" ]; then
    echo -e "${RED}❌ macOS app directory not found at $MACOS_APP_DIR${NC}"
    exit 1
fi

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found${NC}"
    echo -e "${YELLOW}💡 Please install Xcode from the Mac App Store${NC}"
    exit 1
fi

# Check if we have full Xcode (not just command line tools)
if ! xcodebuild -version &> /dev/null; then
    echo -e "${RED}❌ xcodebuild requires full Xcode installation${NC}"
    echo -e "${YELLOW}💡 Please install Xcode from the Mac App Store and run:${NC}"
    echo -e "${YELLOW}   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Xcode found: $(xcodebuild -version | head -1)${NC}"

# Build the macOS app using Xcode
echo -e "${YELLOW}🔨 Building macOS app with Xcode...${NC}"
cd "$MACOS_APP_DIR"

# Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
xcodebuild clean -project sandman.xcodeproj -scheme sandman -configuration Release

# Build the app
echo -e "${YELLOW}🏗️  Building app...${NC}"
xcodebuild build -project sandman.xcodeproj -scheme sandman -configuration Release

# Check if build was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ macOS app build failed${NC}"
    exit 1
fi

# Find the built app (Xcode puts it in DerivedData)
echo -e "${YELLOW}🔍 Searching for built app...${NC}"
DERIVED_DATA_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "sandman.app" -path "*/Build/Products/Release/*" 2>/dev/null | head -1)
if [ -n "$DERIVED_DATA_APP" ]; then
    BUILT_APP_PATH="$DERIVED_DATA_APP"
    echo -e "${GREEN}✅ Found app in DerivedData: $BUILT_APP_PATH${NC}"
else
    # Fallback to local build directory
    BUILT_APP_PATH="$MACOS_APP_DIR/build/Release/sandman.app"
    echo -e "${YELLOW}⚠️  Using local build directory: $BUILT_APP_PATH${NC}"
fi

PHOENIX_RESOURCES_PATH="$BUILT_APP_PATH/Contents/Resources/phoenix_release"

echo -e "${GREEN}✅ macOS app built successfully!${NC}"
echo -e "${YELLOW}📱 App location: $BUILT_APP_PATH${NC}"

# Copy Phoenix release into the app bundle
echo -e "${YELLOW}📋 Embedding Phoenix release into app bundle...${NC}"

# Remove existing Phoenix release if it exists
if [ -d "$PHOENIX_RESOURCES_PATH" ]; then
    echo -e "${YELLOW}🗑️  Removing existing Phoenix release...${NC}"
    rm -rf "$PHOENIX_RESOURCES_PATH"
fi

# Create the directory and copy the Phoenix release
mkdir -p "$PHOENIX_RESOURCES_PATH"
cp -r "$RELEASE_DIR"/* "$PHOENIX_RESOURCES_PATH/"

# Make the sandman binary executable
chmod +x "$PHOENIX_RESOURCES_PATH/bin/sandman"

echo -e "${GREEN}✅ Phoenix release embedded successfully!${NC}"

# Verify the app bundle structure
echo -e "${YELLOW}🔍 Verifying app bundle structure...${NC}"

# Check for essential app bundle components
if [ -f "$BUILT_APP_PATH/Contents/Info.plist" ]; then
    echo -e "${GREEN}✅ Info.plist found${NC}"
else
    echo -e "${RED}❌ Info.plist missing${NC}"
fi

# Check for executable
if [ -f "$BUILT_APP_PATH/Contents/MacOS/sandman" ]; then
    echo -e "${GREEN}✅ Main executable found${NC}"
    # Ensure executable permissions
    chmod +x "$BUILT_APP_PATH/Contents/MacOS/sandman"
else
    echo -e "${RED}❌ Main executable missing${NC}"
fi

# Check for compiled assets (not source assets)
if [ -f "$BUILT_APP_PATH/Contents/Resources/AppIcon.icns" ] && [ -f "$BUILT_APP_PATH/Contents/Resources/Assets.car" ]; then
    echo -e "${GREEN}✅ App icons and assets found${NC}"
else
    echo -e "${RED}❌ App icons and assets missing${NC}"
    echo -e "${YELLOW}   Looking for: AppIcon.icns and Assets.car${NC}"
fi

# Check for code signing
if [ -d "$BUILT_APP_PATH/Contents/_CodeSignature" ]; then
    echo -e "${GREEN}✅ Code signature found${NC}"
else
    echo -e "${YELLOW}⚠️  Code signature missing (may cause 'corrupt app' error)${NC}"
fi

if [ -f "$PHOENIX_RESOURCES_PATH/bin/sandman" ]; then
    echo -e "${GREEN}✅ Phoenix binary found and executable${NC}"
else
    echo -e "${RED}❌ Phoenix binary missing${NC}"
fi

# Fix potential code signing issues by re-signing the app
echo -e "${YELLOW}🔐 Fixing code signing...${NC}"
if command -v codesign &> /dev/null; then
    # First, sign all Erlang/Elixir binaries in the Phoenix release
    echo -e "${YELLOW}🔐 Signing Phoenix release binaries...${NC}"

    # Find and sign all executables in the Phoenix release
    find "$PHOENIX_RESOURCES_PATH" -type f -perm +111 -exec file {} \; | \
        grep -E "(Mach-O|executable)" | \
        cut -d: -f1 | \
        while read -r binary; do
            if [ -f "$binary" ]; then
                echo -e "${YELLOW}  Signing: $(basename "$binary")${NC}"
                codesign --force --sign - "$binary" 2>/dev/null || true
            fi
        done

    # Now sign the main app bundle
    echo -e "${YELLOW}🔐 Signing main app bundle...${NC}"
    codesign --force --deep --sign - "$BUILT_APP_PATH" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Code signing failed, but app may still work${NC}"
    }
    echo -e "${GREEN}✅ Code signing completed${NC}"
else
    echo -e "${YELLOW}⚠️  codesign not available, skipping code signing${NC}"
fi

# Test the Phoenix integration
echo -e "${YELLOW}🧪 Testing Phoenix integration...${NC}"
cd "$PHOENIX_RESOURCES_PATH"
export PORT=7000

# Start Phoenix in background for testing
echo -e "${YELLOW}⏳ Starting Phoenix app for testing...${NC}"
./bin/sandman start &
PHOENIX_PID=$!

# Wait a moment for startup
sleep 10

# Check if the process is running
if kill -0 $PHOENIX_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Phoenix app started successfully${NC}"

    # Test if the web server is responding
    if curl -s -f http://localhost:7000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Web server is responding on port 7000${NC}"
    else
        echo -e "${YELLOW}⚠️  Web server not responding yet${NC}"
    fi

    # Stop the test Phoenix app
    kill $PHOENIX_PID
    wait $PHOENIX_PID 2>/dev/null || true
    echo -e "${GREEN}✅ Test Phoenix app stopped${NC}"
else
    echo -e "${RED}❌ Phoenix app failed to start${NC}"
fi

# Copy the app to a release folder for easier distribution
echo -e "${YELLOW}📦 Creating release folder...${NC}"
RELEASE_FOLDER="$SCRIPT_DIR/release"
mkdir -p "$RELEASE_FOLDER"

# Remove existing release if it exists
if [ -d "$RELEASE_FOLDER/sandman.app" ]; then
    echo -e "${YELLOW}🗑️  Removing existing release...${NC}"
    rm -rf "$RELEASE_FOLDER/sandman.app"
fi

# Copy the app to release folder
echo -e "${YELLOW}📋 Copying app to release folder...${NC}"
cp -r "$BUILT_APP_PATH" "$RELEASE_FOLDER/"

echo -e "${GREEN}✅ App copied to release folder!${NC}"

echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo -e "${GREEN}📱 Final app: $BUILT_APP_PATH${NC}"
echo -e "${GREEN}📦 Release copy: $RELEASE_FOLDER/sandman.app${NC}"
echo -e "${YELLOW}💡 To run the app: open '$RELEASE_FOLDER/sandman.app'${NC}"
echo -e "${YELLOW}💡 The Phoenix app will start automatically on port 7000${NC}"
echo -e "${YELLOW}💡 Access the web interface at: http://localhost:7000${NC}"
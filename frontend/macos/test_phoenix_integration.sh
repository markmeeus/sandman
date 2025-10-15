#!/bin/bash

# Test script to verify Phoenix integration without building the full macOS app
# This script simulates what the macOS app would do to start the Phoenix process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Testing Phoenix integration...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/sandman/_build/prod/rel/sandman"
SANDBOX_DIR="$SCRIPT_DIR/test_sandbox"

echo -e "${YELLOW}📁 Project root: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}📦 Release directory: $RELEASE_DIR${NC}"
echo -e "${YELLOW}🧪 Sandbox directory: $SANDBOX_DIR${NC}"

# Check if Phoenix release exists
if [ ! -d "$RELEASE_DIR" ]; then
    echo -e "${RED}❌ Phoenix release not found at $RELEASE_DIR${NC}"
    echo -e "${YELLOW}💡 Please build the Phoenix release first with: mix release${NC}"
    exit 1
fi

# Create sandbox directory to simulate app bundle structure
echo -e "${YELLOW}📂 Creating sandbox directory...${NC}"
rm -rf "$SANDBOX_DIR"
mkdir -p "$SANDBOX_DIR/Contents/Resources/phoenix_release"

# Copy the Phoenix release
echo -e "${YELLOW}📋 Copying Phoenix release to sandbox...${NC}"
cp -r "$RELEASE_DIR"/* "$SANDBOX_DIR/Contents/Resources/phoenix_release/"

# Make the sandman binary executable
chmod +x "$SANDBOX_DIR/Contents/Resources/phoenix_release/bin/sandman"

# Test starting the Phoenix app
echo -e "${YELLOW}🚀 Testing Phoenix app startup...${NC}"

cd "$SANDBOX_DIR/Contents/Resources/phoenix_release"

# Set environment variables
export PORT=7000

# Start the Phoenix app in the background
echo -e "${YELLOW}⏳ Starting Phoenix app...${NC}"
./bin/sandman start &
PHOENIX_PID=$!

# Wait a moment for startup
sleep 3

# Check if the process is running
if kill -0 $PHOENIX_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Phoenix app started successfully (PID: $PHOENIX_PID)${NC}"

    # Test if the web server is responding
    echo -e "${YELLOW}🌐 Testing web server response...${NC}"
    if curl -s -f http://localhost:7000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Web server is responding on port 7000${NC}"
    else
        echo -e "${YELLOW}⚠️  Web server not responding yet (may need more time to start)${NC}"
    fi

    # Stop the Phoenix app
    echo -e "${YELLOW}🛑 Stopping Phoenix app...${NC}"
    kill $PHOENIX_PID
    wait $PHOENIX_PID 2>/dev/null || true
    echo -e "${GREEN}✅ Phoenix app stopped${NC}"
else
    echo -e "${RED}❌ Phoenix app failed to start${NC}"
    exit 1
fi

# Clean up sandbox
echo -e "${YELLOW}🧹 Cleaning up sandbox...${NC}"
rm -rf "$SANDBOX_DIR"

echo -e "${GREEN}🎉 Phoenix integration test completed successfully!${NC}"
echo -e "${YELLOW}💡 The macOS app should work the same way when built with Xcode${NC}"

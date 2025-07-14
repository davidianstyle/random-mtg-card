#!/bin/bash

# Universal build script for MTG Card Display
# Detects platform and calls appropriate build script
# Usage: ./scripts/build_universal.sh [debug|release]

set -e

# Default to debug mode
BUILD_MODE=${1:-debug}

echo "🃏 MTG Card Display - Universal Build Script"
echo "Build mode: $BUILD_MODE"

# Detect the operating system
OS=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    echo "Supported platforms: Linux, macOS, Windows"
    exit 1
fi

echo "🔍 Detected platform: $OS"

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the appropriate build script
case $OS in
    "linux")
        echo "📱 Building for Linux..."
        "$SCRIPT_DIR/build_linux.sh" "$BUILD_MODE"
        ;;
    "macos")
        echo "🍎 Building for macOS..."
        "$SCRIPT_DIR/build_macos.sh" "$BUILD_MODE"
        ;;
    "windows")
        echo "🪟 Building for Windows..."
        # Use cmd to run the batch file on Windows
        cmd.exe /c "$SCRIPT_DIR/build_windows.bat" "$BUILD_MODE"
        ;;
    *)
        echo "❌ Unsupported platform: $OS"
        exit 1
        ;;
esac

echo "✅ Universal build completed successfully!"
echo ""
echo "Platform-specific instructions:"
echo "  Linux: See output above for executable location"
echo "  macOS: See output above for app bundle location"
echo "  Windows: See output above for .exe location"
echo ""
echo "To run tests on any platform:"
echo "  flutter test"
echo "  flutter test integration_test/"

# Make the script executable
chmod +x "$0" 
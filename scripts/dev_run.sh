#!/bin/bash

# Cross-platform development script with hot reload
# Usage: ./scripts/dev_run.sh [device]

set -e

# Device parameter (optional)
DEVICE=${1:-"auto"}

echo "🔥 MTG Card Display - Development Mode (Hot Reload)"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Check if we're in the project directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the project root directory."
    exit 1
fi

# Detect the operating system and set appropriate device
if [ "$DEVICE" = "auto" ]; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        DEVICE="linux"
        echo "🔍 Auto-detected platform: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        DEVICE="macos"
        echo "🔍 Auto-detected platform: macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        DEVICE="windows"
        echo "🔍 Auto-detected platform: Windows"
    else
        echo "❌ Unsupported operating system: $OSTYPE"
        echo "Manually specify device: ./scripts/dev_run.sh [linux|macos|windows]"
        exit 1
    fi
else
    echo "🔍 Using specified device: $DEVICE"
fi

# Enable desktop support for the platform
case $DEVICE in
    "linux")
        echo "🔧 Enabling Linux desktop support..."
        flutter config --enable-linux-desktop
        ;;
    "macos")
        echo "🔧 Enabling macOS desktop support..."
        flutter config --enable-macos-desktop
        ;;
    "windows")
        echo "🔧 Enabling Windows desktop support..."
        flutter config --enable-windows-desktop
        ;;
esac

echo "📦 Installing dependencies..."
flutter pub get

echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "🚀 Starting development server with hot reload..."
echo "Platform: $DEVICE"
echo ""
echo "💡 Development Tips:"
echo "  - Press 'r' to hot reload"
echo "  - Press 'R' to hot restart"
echo "  - Press 'q' to quit"
echo "  - Press 'h' for help"
echo ""

# Run Flutter with hot reload
flutter run -d "$DEVICE" --hot 
#!/bin/bash

# Build script for MacOS - MTG Card Display
# Usage: ./scripts/build_macos.sh [debug|release]

set -e

# Default to debug mode
BUILD_MODE=${1:-debug}

echo "🃏 MTG Card Display - MacOS Build Script"
echo "Build mode: $BUILD_MODE"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    echo "Visit: https://docs.flutter.dev/get-started/install/macos"
    exit 1
fi

# Check if we're in the project directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the project root directory."
    exit 1
fi

# Check if Xcode is installed (required for MacOS builds)
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Enable MacOS desktop support if not already enabled
echo "🔧 Enabling MacOS desktop support..."
flutter config --enable-macos-desktop

if [ "$BUILD_MODE" = "release" ]; then
    echo "🏗️ Building MacOS release version..."
    flutter build macos --release
    
    echo "✅ Build complete! App bundle at: build/macos/Build/Products/Release/random_mtg_card.app"
    echo "📦 Creating DMG installer..."
    
    # Create a simple DMG (requires additional tools for polished installer)
    if command -v create-dmg &> /dev/null; then
        create-dmg \
            --volname "MTG Card Display" \
            --app-drop-link 600 185 \
            "build/MTG_Card_Display.dmg" \
            "build/macos/Build/Products/Release/random_mtg_card.app"
        echo "✅ DMG created: build/MTG_Card_Display.dmg"
    else
        echo "💡 Install create-dmg to generate DMG installer: brew install create-dmg"
    fi
else
    echo "🏗️ Building MacOS debug version..."
    flutter build macos --debug
    
    echo "✅ Build complete! App bundle at: build/macos/Build/Products/Debug/random_mtg_card.app"
fi

echo "🎉 MacOS build completed successfully!"
echo ""
echo "To run the app:"
if [ "$BUILD_MODE" = "release" ]; then
    echo "  open build/macos/Build/Products/Release/random_mtg_card.app"
else
    echo "  open build/macos/Build/Products/Debug/random_mtg_card.app"
fi
echo ""
echo "To run tests:"
echo "  flutter test"
echo "  flutter test integration_test/"
echo ""
echo "To run with development features:"
echo "  flutter run -d macos"

# Make the script executable
chmod +x "$0" 
#!/bin/bash

# Build and run script for MTG Card Display
# Usage: ./scripts/build_and_run.sh [debug|release]

set -e

# Default to debug mode
BUILD_MODE=${1:-debug}

echo "🃏 MTG Card Display - Build and Run Script"
echo "Build mode: $BUILD_MODE"

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

echo "📦 Installing dependencies..."
flutter pub get

echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

if [ "$BUILD_MODE" = "release" ]; then
    echo "🏗️  Building release version..."
    flutter build linux --release
    
    echo "🚀 Running release build..."
    ./build/linux/x64/release/bundle/random_mtg_card
else
    echo "🏗️  Building debug version..."
    flutter build linux --debug
    
    echo "🚀 Running debug build..."
    ./build/linux/x64/debug/bundle/random_mtg_card
fi 
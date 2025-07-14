#!/bin/bash

# Build script for Linux - MTG Card Display
# Usage: ./scripts/build_linux.sh [debug|release]

set -e

# Default to debug mode
BUILD_MODE=${1:-debug}

echo "🃏 MTG Card Display - Linux Build Script"
echo "Build mode: $BUILD_MODE"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    echo "Visit: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

# Check if we're in the project directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Please run this script from the project root directory."
    exit 1
fi

# Check for required Linux build dependencies
echo "🔧 Checking Linux build dependencies..."
if ! pkg-config --exists gtk+-3.0; then
    echo "❌ GTK+ 3.0 development libraries not found."
    echo "Install with: sudo apt-get install libgtk-3-dev"
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Enable Linux desktop support if not already enabled
echo "🔧 Enabling Linux desktop support..."
flutter config --enable-linux-desktop

if [ "$BUILD_MODE" = "release" ]; then
    echo "🏗️ Building Linux release version..."
    flutter build linux --release
    
    echo "✅ Build complete! Executable at: build/linux/x64/release/bundle/random_mtg_card"
    
    # Create a simple run script for the bundle
    cat > build/linux/x64/release/run_mtg_card.sh << 'EOF'
#!/bin/bash
# Simple run script for MTG Card Display

# Get the directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the application
exec "$DIR/bundle/random_mtg_card" "$@"
EOF
    chmod +x build/linux/x64/release/run_mtg_card.sh
    echo "✅ Run script created: build/linux/x64/release/run_mtg_card.sh"
    
    # Create a desktop file for system integration
    cat > build/linux/x64/release/mtg-card-display.desktop << 'EOF'
[Desktop Entry]
Name=MTG Card Display
Comment=Display random Magic: The Gathering cards
Exec=PLACEHOLDER_PATH/bundle/random_mtg_card
Icon=PLACEHOLDER_PATH/bundle/data/flutter_assets/assets/icons/app_icon.png
Terminal=false
Type=Application
Categories=Games;Entertainment;
EOF
    echo "✅ Desktop file created: build/linux/x64/release/mtg-card-display.desktop"
    echo "   (Edit paths before installing to system)"
    
else
    echo "🏗️ Building Linux debug version..."
    flutter build linux --debug
    
    echo "✅ Build complete! Executable at: build/linux/x64/debug/bundle/random_mtg_card"
fi

echo "🎉 Linux build completed successfully!"
echo ""
echo "To run the app:"
if [ "$BUILD_MODE" = "release" ]; then
    echo "  ./build/linux/x64/release/bundle/random_mtg_card"
    echo "  or use: ./build/linux/x64/release/run_mtg_card.sh"
else
    echo "  ./build/linux/x64/debug/bundle/random_mtg_card"
fi
echo ""
echo "To run tests:"
echo "  flutter test"
echo "  flutter test integration_test/"
echo ""
echo "To run with development features:"
echo "  flutter run -d linux"
echo ""
echo "For Raspberry Pi deployment:"
echo "  1. Copy the entire bundle directory to your Pi"
echo "  2. Ensure the Pi has the required libraries: sudo apt-get install libgtk-3-0"
echo "  3. Run the executable directly or use the run script"

# Make the script executable
chmod +x "$0" 
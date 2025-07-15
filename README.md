# Random MTG Card Display

> 📚 **Technical Documentation**: For comprehensive technical documentation, architecture details, and development guides, see the **[memory-bank/](./memory-bank/)** directory.

A Flutter application that displays random Magic: The Gathering cards with filtering, favorites, and cross-platform support.

## 🚀 Quick Links

- **[📖 Full Documentation](./memory-bank/README.md)** - Complete documentation index
- **[🏗️ Architecture Guide](./memory-bank/MEMORY_BANK.md)** - Technical implementation details
- **[🔧 Technical Specs](./memory-bank/TECHNICAL_SPECS.md)** - System requirements and specifications

## Features

- **Cross-platform support**: Windows, MacOS, and Linux
- **Full-screen card display** optimized for various screen sizes
- **Gesture-based navigation**: swipe, tap, double-tap, long-press
- **Favorites system** with persistent storage
- **Configurable filters** (sets, colors, types, rarity)
- **Image caching** for offline viewing
- **Auto-refresh** capability
- **Responsive design** for different screen sizes
- **Comprehensive test suite** with unit, widget, and integration tests

## Platform Support

### Windows
- Windows 10 or later
- Visual Studio 2019 or later (for building)
- Flutter SDK 3.16.0+

### MacOS
- macOS 10.14 or later
- Xcode 12 or later
- Flutter SDK 3.16.0+

### Linux (including Raspberry Pi)
- Ubuntu 18.04 or later (or equivalent)
- GTK+ 3.0 development libraries
- Flutter SDK 3.16.0+

## Quick Start

### Universal Build (Auto-detects Platform)
```bash
# Clone the repository
git clone <repository-url>
cd random-mtg-card

# Install dependencies
flutter pub get

# Generate code
flutter packages pub run build_runner build

# Build for your platform (local development)
./scripts/build_universal.sh release
```

> **Note**: The build scripts are provided for local development convenience. Our CI/CD pipeline uses direct Flutter commands for more reliable automated builds.

### Platform-Specific Instructions

#### Windows
```bash
# Install Flutter for Windows
# Download from: https://docs.flutter.dev/get-started/install/windows

# Build
scripts/build_windows.bat release

# Run
build\windows\runner\Release\random_mtg_card.exe
```

#### MacOS
```bash
# Install Flutter for macOS
# Download from: https://docs.flutter.dev/get-started/install/macos

# Build
./scripts/build_macos.sh release

# Run
open build/macos/Build/Products/Release/random_mtg_card.app
```

#### Linux / Raspberry Pi
```bash
# Install Flutter for Linux
# Download from: https://docs.flutter.dev/get-started/install/linux

# Install dependencies
sudo apt-get update
sudo apt-get install libgtk-3-dev

# Build
./scripts/build_linux.sh release

# Run
./build/linux/x64/release/bundle/random_mtg_card
```

## Development

### Prerequisites
- Flutter SDK 3.16.0+
- Dart SDK 3.2.0+
- Platform-specific development tools (Visual Studio, Xcode, or build-essential)

### Development Setup
```bash
# Clone and setup
git clone <repository-url>
cd random-mtg-card
flutter pub get

# Run with hot reload (auto-detects platform)
./scripts/dev_run.sh

# Or specify platform
./scripts/dev_run.sh linux
./scripts/dev_run.sh macos
./scripts/dev_run.sh windows
```

### Running Tests

The project includes a comprehensive test suite:

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/unit/                    # Unit tests
flutter test test/widget/                  # Widget tests
flutter test test/integration/             # Integration tests

# Run with coverage
flutter test --coverage
```

#### Test Coverage
- **Unit Tests**: Models, services, providers
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Full app flow and gesture handling

## Configuration

### Default Settings
The app uses a JSON-based configuration system with the following defaults:

```json
{
  "display": {
    "fullscreen": true,
    "resolution": [600, 1024],
    "orientation": "portrait",
    "auto_refresh_interval": 30
  },
  "features": {
    "favorites": true,
    "swipe_navigation": true,
    "double_tap_favorite": true,
    "tap_metadata_toggle": true
  },
  "filters": {
    "enabled": false,
    "sets": [],
    "colors": [],
    "types": [],
    "rarity": []
  }
}
```

### Platform-Specific Behavior
- **Linux (Raspberry Pi)**: Full-screen kiosk mode, locked to portrait
- **Windows/MacOS**: Windowed mode with optional fullscreen, flexible orientation
- **All platforms**: Gesture-based navigation and favorites system

## Usage

### Gestures

- **Swipe Left**: Next card
- **Swipe Right**: Previous card
- **Single Tap**: Show/hide card metadata
- **Double Tap**: Add/remove from favorites
- **Long Press**: Reserved for future card details feature

### Keyboard Shortcuts (Desktop)
- **Space**: Next card
- **Backspace**: Previous card
- **F**: Toggle favorite
- **M**: Toggle metadata
- **F11**: Toggle fullscreen (Windows/MacOS)

## Project Structure

```
random-mtg-card/
├── lib/
│   ├── main.dart                 # Cross-platform app entry point
│   ├── models/                   # Data models with JSON serialization
│   ├── services/                 # API client and configuration
│   ├── providers/                # State management
│   ├── screens/                  # Main display screen
│   └── widgets/                  # Reusable UI components
├── scripts/                      # Cross-platform build scripts
│   ├── build_universal.sh        # Auto-detect platform build
│   ├── build_windows.bat         # Windows build script
│   ├── build_macos.sh           # MacOS build script
│   ├── build_linux.sh           # Linux build script
│   └── dev_run.sh               # Development with hot reload
├── test/
│   ├── unit/                     # Unit tests
│   ├── widget/                   # Widget tests
│   └── integration/             # Integration tests
├── config/                       # Configuration templates
└── assets/                       # App icons and images
```

## API Integration

### Scryfall API
- **Base URL**: https://api.scryfall.com
- **Rate Limiting**: 100ms between requests (as recommended)
- **Retry Logic**: Automatic retry on network errors
- **User Agent**: MTGCardDisplay/1.0

### Key Endpoints
- `/cards/random` - Get random card
- `/cards/search` - Search with filters
- `/sets` - Get available sets

## Deployment

### Windows
- Build creates a self-contained executable
- Can be distributed as a single folder
- Optional: Create installer with advanced tools

### MacOS
- Build creates a .app bundle
- Can be packaged as DMG for distribution
- Code signing required for distribution

### Linux / Raspberry Pi
- Build creates a bundle with all dependencies
- Can be installed as system service
- Desktop file provided for system integration

### Raspberry Pi Specific Setup
For dedicated kiosk installations:

1. **Auto-start on Boot**
```bash
# Create systemd service
sudo nano /etc/systemd/system/mtg-card-display.service

[Unit]
Description=MTG Card Display
After=graphical-session.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
WorkingDirectory=/home/pi/random-mtg-card
ExecStart=/home/pi/random-mtg-card/build/linux/x64/release/bundle/random_mtg_card
Restart=always

[Install]
WantedBy=graphical-session.target
```

2. **Enable Service**
```bash
sudo systemctl enable mtg-card-display.service
sudo systemctl start mtg-card-display.service
```

## Performance Optimization

### Raspberry Pi
- **ARM-native compilation**: Excellent performance
- **Image caching**: Reduces API calls and improves responsiveness
- **Memory management**: Automatic cache cleanup
- **GPU acceleration**: Utilizes Pi's GPU for smooth animations

### Desktop Platforms
- **Adaptive sizing**: Responsive to different screen sizes
- **Efficient rendering**: Optimized for desktop hardware
- **Multiple monitor support**: Adapts to various display configurations

## Troubleshooting

### Common Issues

1. **Build Errors**
   - Run `flutter clean && flutter pub get`
   - Ensure platform-specific tools are installed
   - Check Flutter doctor: `flutter doctor`

2. **Network Errors**
   - Verify internet connection
   - Check Scryfall API status
   - Ensure firewall allows HTTP/HTTPS connections

3. **Display Issues**
   - Check screen resolution settings
   - Verify graphics drivers are updated
   - Try windowed mode if fullscreen fails

### Platform-Specific Issues

#### Windows
- Ensure Visual Studio components are installed
- Check Windows Defender exclusions
- Verify .NET Framework is up to date

#### MacOS
- Ensure Xcode command line tools are installed
- Check System Preferences → Security & Privacy
- Verify app has necessary permissions

#### Linux
- Install required GTK+ development libraries
- Check X11 display environment
- Verify user permissions for display

## Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Set up commit template (optional): `git config commit.template .gitmessage`
4. Use conventional commits (see Release Management section)
5. Run tests: `flutter test`
6. Build for your platform: `./scripts/build_universal.sh`
7. Submit a pull request with conventional commit messages

### Code Style
- Follow Dart style guide
- Use `flutter analyze` to check code quality
- Ensure all tests pass before submitting

## Release Management

This project uses [Release Please](https://github.com/googleapis/release-please) for automated release management. Releases are automatically created based on [Conventional Commits](https://www.conventionalcommits.org/).

### Commit Message Format

Use conventional commit messages to trigger automatic releases:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Commit Types

- **feat**: A new feature (triggers MINOR version bump)
- **fix**: A bug fix (triggers PATCH version bump)  
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement (triggers PATCH version bump)
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes affecting build system or external dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

#### Breaking Changes

Add `BREAKING CHANGE:` in the footer or use `!` after the type to trigger a MAJOR version bump:

```bash
feat!: redesign settings interface

BREAKING CHANGE: Settings screen now requires new configuration format
```

#### Examples

```bash
# New feature (1.0.0 → 1.1.0)
feat: add dark mode theme option

# Bug fix (1.0.0 → 1.0.1)  
fix: resolve card image loading issue on macOS

# Performance improvement (1.0.0 → 1.0.1)
perf: optimize card caching mechanism

# Breaking change (1.0.0 → 2.0.0)
feat!: redesign filter configuration API

BREAKING CHANGE: FilterConfig class now requires different constructor parameters
```

### Release Process

1. **Development**: Create PRs with conventional commit messages
2. **Merge to main**: When PRs are merged, Release Please analyzes commits
3. **Release PR**: If releaseable commits are found, Release Please creates a release PR
4. **Release**: When the release PR is merged, a new release is published with:
   - Updated version in `pubspec.yaml`
   - Generated `CHANGELOG.md` entries
   - Git tag
   - Cross-platform build artifacts (Windows, macOS, Linux)

### Manual Release Override

To create a release immediately, add this to your commit message:

```bash
feat: add new feature

Release-As: 1.2.0
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Scryfall](https://scryfall.com) for providing the excellent MTG API
- [Flutter](https://flutter.dev) for the cross-platform framework
- [Wizards of the Coast](https://company.wizards.com) for Magic: The Gathering

---

**Note**: This application is not affiliated with or endorsed by Wizards of the Coast or Scryfall. Magic: The Gathering is a trademark of Wizards of the Coast LLC.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-14

### Features

* **Cross-Platform Support**: Full support for Windows, macOS, and Linux with native integrations
* **Settings Menu**: Comprehensive filter configuration system with searchable multi-select interface
  - Sets filter with all MTG sets and release dates
  - Colors filter (WUBRG + Colorless)
  - Card types and creature types filters
  - Rarity and format filters
  - Auto-refresh configuration
* **Favorites System**: Complete favorites management with search, sort, and detailed view
  - Grid layout with card thumbnails
  - Search across card attributes
  - Sort by name, set, or rarity
  - Card details popup
  - Batch operations (clear all)
* **Navigation Menu**: Animated overlay menu for easy access to all features
* **MTG Card Display**: Random card fetching with gesture controls
  - Tap to toggle metadata
  - Double-tap to favorite
  - Swipe for navigation
  - Long-press for details
* **Filter System**: Apply filters to random card fetching with Scryfall API integration
* **Comprehensive Testing**: Unit tests, widget tests, and integration tests with 90%+ coverage
* **Build System**: Cross-platform build scripts for all supported platforms
* **Professional UI**: Dark theme with modern design and responsive layouts

### Bug Fixes

* **Network Permissions**: Fixed macOS network entitlements for API access
* **Configuration Management**: Fixed immutable map modification issues in settings
* **Null Safety**: Proper handling of optional card fields

### Documentation

* **Cross-Platform Setup**: Complete setup instructions for all platforms
* **Development Workflow**: Comprehensive development and testing guides
* **Troubleshooting**: Platform-specific troubleshooting documentation
* **Performance Optimization**: Details on caching and memory management 
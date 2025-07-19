# Random MTG Card Display - Project Overview

## Project Purpose
A full-screen application for displaying random Magic: The Gathering cards from Scryfall API. Originally designed for Raspberry Pi with 7" Waveshare display (1024x600), now expanded to support web browsers for cross-platform compatibility.

## Platform Support

### Primary Target: Raspberry Pi
- **Device**: Raspberry Pi (ARM architecture)
- **Display**: 7" Waveshare touchscreen (600x1024 portrait resolution)
- **Interaction**: Gesture-based, maximized card display
- **Network**: WiFi connection for API calls

### Secondary Target: Web Browsers
- **Deployment**: Web application accessible via any modern browser
- **Display**: Responsive design adapting to various screen sizes
- **Interaction**: Touch/mouse support with same gesture patterns
- **Network**: Direct API calls from browser (CORS-enabled)
- **Benefits**: Easy testing, deployment to Pi via web server, no OpenGL dependencies

### Cross-Platform Features
1. **Unified Codebase**: Single Flutter codebase supporting desktop, mobile, and web
2. **Platform-Aware Services**: Automatic fallbacks for platform-specific features
3. **Consistent UI/UX**: Same interface and interactions across all platforms
4. **Smart Caching**: Memory-based caching for web, file-based for desktop/mobile

## Technical Requirements

### Hardware Specifications (Raspberry Pi)
- **Device**: Raspberry Pi (ARM architecture)
- **Display**: 7" Waveshare touchscreen (600x1024 portrait resolution)
- **Interaction**: Gesture-based, maximized card display
- **Network**: WiFi connection for API calls

### Web Platform Requirements
- **Browser**: Modern browsers supporting ES2017+ and WebAssembly
- **Network**: Direct internet access for Scryfall API calls
- **Storage**: LocalStorage/IndexedDB for preferences (no file system caching)
- **Display**: Responsive design supporting mobile and desktop viewports

### Core Features (All Platforms)
1. **Random Card Display**: Fetch and display random MTG cards from Scryfall API
2. **Full-Screen Mode**: Utilize maximum available display area
3. **Gesture-Based Interaction**: 
   - Swipe left/right for navigation
   - Double-tap to favorite cards
   - Single tap to show/hide metadata
   - Long press for card details
4. **Maximized Card Display**: Minimal UI elements to show largest possible card
5. **Extensible Configuration**: Easy parameterization for future features
   - Filter by set/expansion
   - Filter by card type (lands, creatures, etc.)
   - Filter by color/format
   - Timing intervals for auto-refresh

### API Integration
- **Scryfall API**: https://scryfall.com/docs/api
- **Key Endpoints**:
  - `/cards/random` - Get random card
  - `/cards/search` - Search with filters
  - `/sets` - Get set information for filtering

## Current Implementation: Flutter

### ✅ **Flutter (CHOSEN SOLUTION)**
**Best for**: Modern, performant cross-platform UI with web support

**Pros:**
- ✅ Single codebase for desktop, mobile, and web
- ✅ Excellent performance on ARM (Pi) and web browsers
- ✅ Beautiful, modern UI out of the box
- ✅ Great touch handling across all platforms
- ✅ Built-in full-screen support
- ✅ Strong HTTP client for API calls
- ✅ Web deployment without additional setup
- ✅ No OpenGL dependencies on web (solves Pi graphics issues)

**Implementation Status:**
- ✅ Desktop/Mobile: Complete with file-based caching and logging
- ✅ Web: Complete with fallback implementations for file operations
- ✅ Conditional compilation: Platform-specific code paths
- ✅ Service locator: Dependency injection works across platforms
- ✅ Responsive design: Adapts to different screen sizes

**Web-Specific Adaptations:**
- **File System**: Web stubs for `File`, `Directory`, and path operations
- **Caching**: Memory-only caching (no disk persistence)
- **Logging**: Console-only logging (no file logging)
- **Dependencies**: Platform-aware imports using conditional compilation

### Alternative Framework Options (Historical)

<details>
<summary>Click to expand other framework considerations</summary>

### 1. **Electron + React/Vue** 
**Best for**: Feature-rich UI with web technologies

**Pros:**
- Familiar web development stack
- Excellent for responsive UI design
- Rich ecosystem of libraries
- Easy to prototype and iterate
- Good touch event handling
- Native full-screen APIs

**Cons:**
- Higher memory usage (concern on Pi)
- Slower startup time
- More complex deployment

### 2. **Python + Tkinter/PyQt**
**Best for**: Simple, lightweight solution

**Pros:**
- Lightweight and fast on Pi
- Excellent for simple UIs
- Great API integration with `requests`
- Easy configuration management
- Quick development cycle
- Good PIL/Pillow support for image handling

**Cons:**
- Limited modern UI capabilities
- Touch interaction requires extra work
- Less polished looking UI

### 3. **Python + Kivy**
**Best for**: Touch-first applications

**Pros:**
- Built specifically for touch interfaces
- Great performance on Pi
- Modern UI capabilities
- Excellent for full-screen apps
- Good gesture support
- Cross-platform

**Cons:**
- Learning curve for Kivy-specific concepts
- Smaller community than web frameworks
- Custom styling required

### 4. **Web App (HTML/CSS/JS) + Kiosk Mode**
**Best for**: Simple, universally compatible solution

**Pros:**
- Runs in any browser
- Easy to style and make responsive
- Simple deployment (just serve files)
- Familiar technologies
- Easy to test on any device

**Cons:**
- Requires browser in kiosk mode
- Limited system integration
- Depends on browser performance

</details>

## Recommended Architecture

```
┌─────────────────────┐
│   Configuration     │
│   (JSON/SharedPrefs)│
└─────────────────────┘
           │
┌─────────────────────┐
│   Main App          │
│   - State Management│
│   - UI Controller   │
│   - Service Locator │
└─────────────────────┘
           │
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Scryfall API      │    │   Cache Service     │    │   Logger Service    │
│   Client            │    │   (Platform-aware)  │    │   (Platform-aware)  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
           │                           │                           │
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Display Manager   │    │   File/Memory Cache │    │   Console/File Log  │
│   - Full-screen     │    │   (Conditional)     │    │   (Conditional)     │
│   - Touch Events    │    │                     │    │                     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

## Deployment Options

### Raspberry Pi Deployment
1. **Desktop Application**: Flutter Linux build with file system access
2. **Web Application**: Serve Flutter web build with local HTTP server

### Web Deployment
1. **Static Hosting**: Deploy `build/web` to any web server (Apache, Nginx, CDN)
2. **Cloud Platforms**: Firebase Hosting, Netlify, Vercel, GitHub Pages
3. **Local Network**: Simple HTTP server for Pi access via browser

## Cross-Platform Benefits

### Development
- **Single Codebase**: Maintain one Flutter project for all platforms
- **Shared Logic**: Business logic, API client, and state management shared
- **Platform Testing**: Easy testing on development machine before Pi deployment
- **Rapid Iteration**: Web development workflow with hot reload

### Deployment
- **Flexibility**: Choose between native or web deployment on Pi
- **Backup Solution**: Web version works when desktop version has issues
- **Accessibility**: Remote access via network browser
- **Compatibility**: Works around Pi OpenGL/graphics driver issues

Would you like me to proceed with detailed implementation documentation for any specific platform or deployment scenario? 
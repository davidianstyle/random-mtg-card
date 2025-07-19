# Technical Specifications - Random MTG Card Display

## Multi-Platform Support

### Primary Platform: Raspberry Pi (Desktop)
#### Screen Resolution: 1024x600 (7" Waveshare) - Vertical Orientation
- **Rotated Resolution**: 600x1024 (portrait mode)
- **Aspect Ratio**: 0.586:1 (≈3:5)
- **Pixel Density**: ~170 PPI
- **Touch**: Capacitive touch support
- **Orientation**: Portrait (vertical)

#### Card Display Considerations
- **MTG Card Aspect Ratio**: 2.5:3.5 (≈0.714:1)
- **Optimal Card Size**: 
  - Width: ~540-580px (maximizes horizontal space)
  - Height: ~756-812px (maximizes vertical space)
  - Perfect fit for portrait orientation
  - Minimal UI elements to maximize card visibility

### Secondary Platform: Web Browsers
#### Browser Compatibility
- **Minimum Requirements**: ES2017+, WebAssembly support
- **Supported Browsers**: Chrome 84+, Firefox 79+, Safari 14+, Edge 84+
- **Mobile Browsers**: iOS Safari 14+, Chrome Mobile 84+
- **Responsive Breakpoints**:
  - Mobile: 320-768px width
  - Tablet: 768-1024px width  
  - Desktop: 1024px+ width

#### Web-Specific Considerations
- **No File System Access**: Uses browser storage APIs instead
- **CORS**: Direct API calls to Scryfall (CORS-enabled)
- **Image Loading**: Network-only (no local file caching)
- **Storage**: LocalStorage for preferences, no disk cache
- **Performance**: WebAssembly compilation for Flutter engine

### Cross-Platform Implementation
#### Platform Detection
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific implementation
} else {
  // Desktop/mobile implementation  
}
```

#### Conditional Imports
```dart
// Cache Service
import 'dart:io' if (dart.library.js) 'cache_service_web.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.js) 'cache_service_web.dart';

// Logger Service  
import 'dart:io' if (dart.library.js) 'logger_web.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.js) 'logger_web.dart';
```

## Scryfall API Integration

### Key Endpoints
```
GET https://api.scryfall.com/cards/random
GET https://api.scryfall.com/cards/search?q={query}
GET https://api.scryfall.com/sets
```

### Card Data Structure (Key Fields)
```json
{
  "id": "uuid",
  "name": "Card Name",
  "mana_cost": "{3}{U}{U}",
  "type_line": "Creature — Human Wizard",
  "oracle_text": "Card description...",
  "image_uris": {
    "small": "url",
    "normal": "url", 
    "large": "url",
    "png": "url",
    "art_crop": "url",
    "border_crop": "url"
  },
  "set": "set_code",
  "set_name": "Set Name",
  "rarity": "common|uncommon|rare|mythic",
  "colors": ["W", "U", "B", "R", "G"]
}
```

### Image Quality Selection
- **Primary**: `image_uris.large` (672x936px) - Good quality for display
- **Fallback**: `image_uris.normal` (488x680px) - Smaller but acceptable
- **Consider**: `image_uris.png` for highest quality if bandwidth allows

## Configuration Schema

### config.json Structure (Desktop) / SharedPreferences (All Platforms)
```json
{
  "display": {
    "fullscreen": true,
    "resolution": [600, 1024],
    "orientation": "portrait",
    "auto_refresh_interval": 30,
    "show_metadata_on_tap": true,
    "metadata_auto_hide_delay": 3
  },
  "filters": {
    "enabled": false,
    "sets": [],
    "colors": [],
    "types": [],
    "rarity": [],
    "format": "standard"
  },
  "features": {
    "favorites": true,
    "favorite_indicator": true,
    "swipe_navigation": true,
    "double_tap_favorite": true,
    "tap_metadata_toggle": true,
    "long_press_details": true,
    "offline_mode": false
  },
  "api": {
    "base_url": "https://api.scryfall.com",
    "timeout": 10,
    "retry_attempts": 3,
    "cache_images": true
  }
}
```

## Platform-Specific Service Implementations

### Cache Service Implementation
#### Desktop/Mobile (File-based)
```dart
class FileCache extends Cache<Uint8List> {
  // Full file system implementation
  Future<Result<Uint8List>> get(String key) async {
    final cacheFile = _getCacheFile(key);
    final data = await cacheFile.readAsBytes();
    return Success(Uint8List.fromList(data));
  }
}
```

#### Web (Memory-only)
```dart
class FileCache extends Cache<Uint8List> {
  // Web stub implementation
  Future<Result<Uint8List>> get(String key) async {
    if (kIsWeb) {
      return const Failure(CacheError(message: 'Cache miss - web mode'));
    }
    // ... file implementation
  }
}
```

### Logger Implementation
#### Desktop/Mobile (File + Console)
```dart
class FileLogHandler extends LogHandler {
  // File logging with rotation
  void handle(LogEntry entry) {
    if (!kIsWeb) {
      _logSink?.writeln(jsonEncode(entry.toJson()));
    }
  }
}
```

#### Web (Console-only)
```dart
class FileLogHandler extends LogHandler {
  // Web stub - no file operations
  void handle(LogEntry entry) {
    if (!kIsWeb) {
      _logSink?.writeln(jsonEncode(entry.toJson()));
    }
    // Console logging still works via developer.log()
  }
}
```

### Web Stub Classes
#### File System Stubs
```dart
// Web stubs for dart:io functionality
class File extends FileSystemEntity {
  Future<bool> exists() async => false;
  Future<List<int>> readAsBytes() async => [];
  Future<void> writeAsBytes(List<int> bytes) async {}
  // ... other stub methods
}

class Directory extends FileSystemEntity {
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list() => Stream.empty();
  // ... other stub methods
}

Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('/tmp/docs'); // Web stub
}
```

## UI/UX Design Specifications

### Layout Structure (Responsive)
#### Portrait Mode (Pi + Mobile)
```
┌─────────────────────────────────────┐
│  ❤️ (favorite indicator - top-right)  │
│  ┌─────────────────────────────────┐ │
│  │         MTG Card Image          │ │
│  │        (540x756px)              │ │
│  └─────────────────────────────────┘ │
│       [Card Name - Set Info]        │
└─────────────────────────────────────┘
```

#### Web Responsive Breakpoints
```css
/* Mobile: 320-768px */
.card-container { max-width: 90vw; }

/* Tablet: 768-1024px */  
.card-container { max-width: 600px; }

/* Desktop: 1024px+ */
.card-container { max-width: 800px; }
```

### Touch Interaction Zones (All Platforms)
- **Full Screen**: Entire screen is touch-responsive
- **Favorite Indicator**: Small heart icon (top-right, ~30x30px)
- **Gesture-Based Navigation**: 
  - **Left swipe**: Next card
  - **Right swipe**: Previous card  
  - **Double tap**: Toggle favorite
  - **Single tap**: Show/hide card metadata
  - **Long press**: Show card details/zoom

### Visual Design Guidelines
- **Background**: Pure black (#000000) to make cards pop
- **Card Focus**: Maximum screen real estate for card image
- **Minimal UI**: Only essential elements visible
- **Favorite Indicator**: Small, subtle heart icon (filled/outline)
- **Metadata**: Appears/disappears with tap gesture
- **Loading States**: Smooth transitions, minimal loading indicators
- **Card Transitions**: Smooth slide animations between cards

## Performance Considerations

### Raspberry Pi Optimization
- **Image Caching**: Cache last 10-20 cards locally (file-based)
- **Lazy Loading**: Only load images when needed
- **Memory Management**: Clean up unused images
- **CPU Usage**: Minimize background processing
- **Network**: Efficient API calls, handle offline gracefully

### Web Optimization
- **Bundle Size**: Optimized Flutter web build (~2-3MB gzipped)
- **Loading Performance**: Progressive loading with splash screen
- **Memory Management**: No disk caching, rely on browser cache
- **Network**: Direct API calls, efficient image loading
- **Responsive Images**: Serve appropriate sizes based on device

### Startup Performance
- **Desktop**: Target <5 seconds to first card
- **Web**: Target <3 seconds to interactive (faster due to no file I/O)
- **Config Loading**: Fast configuration parsing
- **API First Call**: Preload first card during startup

## Data Storage Strategies

### Desktop/Mobile Storage
```
~/.mtg-card-display/
├── config.json           # User configuration  
├── favorites.json        # Favorited cards
├── cache/                # Image cache
│   ├── thumbnails/       # Smaller images
│   └── full/             # Full-size images
└── logs/                 # Application logs
```

### Web Storage
```
Browser Storage:
├── LocalStorage          # User preferences
├── SessionStorage        # Temporary app state
└── Browser Cache         # Image caching (automatic)

Note: No persistent file storage available
```

### Favorites Data Structure (All Platforms)
```json
{
  "favorites": [
    {
      "id": "card_uuid",
      "name": "Card Name",
      "set": "set_code", 
      "image_url": "api_url",
      "added_date": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Build and Deployment

### Desktop Build (Linux/Pi)
```bash
flutter build linux --release
./build/linux/x64/release/bundle/random_mtg_card
```

### Web Build
```bash
flutter build web --release
# Serve from build/web directory
python3 -m http.server 8080 --directory build/web
```

### Deployment Options
#### Raspberry Pi
1. **Native App**: Direct execution of Linux build
2. **Web App**: Serve Flutter web build locally
3. **Kiosk Mode**: Browser in fullscreen mode

#### Web Hosting
1. **Static Hosting**: Apache, Nginx, CDN
2. **Cloud Platforms**: Firebase, Netlify, Vercel
3. **Container**: Docker with web server

### Build Artifacts
#### Desktop
- `random_mtg_card` (executable)
- `lib/` (shared libraries)  
- `data/` (Flutter assets)

#### Web
- `index.html` (entry point)
- `main.dart.js` (compiled Dart code)
- `canvaskit/` (Flutter web engine)
- `assets/` (app assets)

## Error Handling

### Network Issues (All Platforms)
- **API Unavailable**: Show last cached card + error message
- **Slow Connection**: Show loading indicator, implement timeout
- **Image Load Failure**: Show placeholder with card details

### Platform-Specific Issues
#### Raspberry Pi
- **OpenGL Errors**: Use web version as fallback
- **Touch Unresponsive**: Implement keyboard fallbacks
- **Memory Constraints**: Automatic cache cleanup

#### Web Platform
- **Browser Compatibility**: Graceful degradation for older browsers
- **Network Restrictions**: Handle CORS and content blocking
- **Storage Limitations**: Work within browser storage quotas

## Security Considerations

### API Security (All Platforms)
- **Rate Limiting**: Respect Scryfall API rate limits
- **HTTPS Only**: Ensure all API calls use HTTPS
- **No API Keys**: Scryfall API is public, no authentication needed

### Platform Security
#### Desktop
- **File Permissions**: Proper permissions for config/cache files
- **Input Validation**: Sanitize all configuration inputs
- **Safe Defaults**: Secure default configuration

#### Web
- **Content Security Policy**: Restrict resource loading
- **HTTPS Deployment**: Secure hosting with SSL/TLS
- **XSS Protection**: Sanitize any user inputs

## Future Extensibility

### Cross-Platform Features
1. **Set Filtering**: Filter by specific MTG sets
2. **Color/Type Filtering**: Show only specific card types
3. **Slideshow Mode**: Auto-advance through random cards
4. **Favorites Gallery**: Browse saved favorite cards
5. **Search Mode**: Search for specific cards
6. **Statistics**: Track viewing history/patterns

### Platform-Specific Extensions
#### Desktop
- **Advanced Caching**: Sophisticated file-based cache management
- **System Integration**: Desktop notifications, system tray
- **Performance Monitoring**: File-based metrics collection

#### Web
- **PWA Support**: Progressive Web App capabilities
- **Share API**: Native sharing integration
- **Background Sync**: Service worker for offline functionality

## Testing Strategy

### Cross-Platform Testing
- **Unit Tests**: Shared business logic
- **Widget Tests**: UI components across platforms
- **Integration Tests**: End-to-end workflows

### Platform-Specific Testing
#### Desktop
- **Performance Testing**: Pi hardware validation
- **Touch Testing**: Actual touch screen interaction
- **File System Testing**: Cache and logging functionality

#### Web
- **Browser Testing**: Cross-browser compatibility
- **Responsive Testing**: Multiple screen sizes
- **Network Testing**: Various connection conditions
- **PWA Testing**: Offline functionality and installation 
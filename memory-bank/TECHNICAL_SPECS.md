# Technical Specifications - Random MTG Card Display

## Display Requirements

### Screen Resolution: 1024x600 (7" Waveshare) - Vertical Orientation
- **Rotated Resolution**: 600x1024 (portrait mode)
- **Aspect Ratio**: 0.586:1 (≈3:5)
- **Pixel Density**: ~170 PPI
- **Touch**: Capacitive touch support
- **Orientation**: Portrait (vertical)

### Card Display Considerations
- **MTG Card Aspect Ratio**: 2.5:3.5 (≈0.714:1)
- **Optimal Card Size**: 
  - Width: ~540-580px (maximizes horizontal space)
  - Height: ~756-812px (maximizes vertical space)
  - Perfect fit for portrait orientation
  - Minimal UI elements to maximize card visibility

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

### config.json Structure
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

## UI/UX Design Specifications

### Layout Structure (Portrait Mode)
```
┌─────────────────────────────────────┐
│                                     │
│  ❤️ (favorite indicator - top-right) │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │                                 │ │
│  │                                 │ │
│  │         MTG Card Image          │ │
│  │        (540x756px)              │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  │                                 │ │
│  └─────────────────────────────────┘ │
│                                     │
│       [Card Name - Set Info]        │
│                                     │
└─────────────────────────────────────┘
```

### Touch Interaction Zones
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
- **Image Caching**: Cache last 10-20 cards locally
- **Lazy Loading**: Only load images when needed
- **Memory Management**: Clean up unused images
- **CPU Usage**: Minimize background processing
- **Network**: Efficient API calls, handle offline gracefully

### Startup Performance
- **Boot Time**: Target <5 seconds to first card
- **Config Loading**: Fast configuration parsing
- **API First Call**: Preload first card during startup

## Data Storage

### Local Storage Requirements
```
~/.mtg-card-display/
├── config.json           # User configuration
├── favorites.json        # Favorited cards
├── cache/                # Image cache
│   ├── thumbnails/       # Smaller images
│   └── full/             # Full-size images
└── logs/                 # Application logs
```

### Favorites Data Structure
```json
{
  "favorites": [
    {
      "id": "card_uuid",
      "name": "Card Name",
      "set": "set_code",
      "image_url": "cached_path",
      "added_date": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Error Handling

### Network Issues
- **API Unavailable**: Show last cached card + error message
- **Slow Connection**: Show loading indicator, implement timeout
- **Image Load Failure**: Show placeholder with card details

### Hardware Issues
- **Touch Unresponsive**: Implement keyboard fallbacks
- **Display Issues**: Graceful degradation for different resolutions
- **Memory Constraints**: Automatic cache cleanup

## Security Considerations

### API Security
- **Rate Limiting**: Respect Scryfall API rate limits
- **HTTPS Only**: Ensure all API calls use HTTPS
- **No API Keys**: Scryfall API is public, no authentication needed

### Local Security
- **File Permissions**: Proper permissions for config/cache files
- **Input Validation**: Sanitize all configuration inputs
- **Safe Defaults**: Secure default configuration

## Future Extensibility

### Planned Features
1. **Set Filtering**: Filter by specific MTG sets
2. **Color/Type Filtering**: Show only specific card types
3. **Slideshow Mode**: Auto-advance through random cards
4. **Favorites Gallery**: Browse saved favorite cards
5. **Search Mode**: Search for specific cards
6. **Statistics**: Track viewing history/patterns

### Architecture for Extensions
- **Plugin System**: Modular filter system
- **Event System**: Hooks for custom behaviors
- **Configuration API**: Easy addition of new settings
- **Theme System**: Customizable UI themes

## Testing Strategy

### Unit Tests
- API client functionality
- Configuration parsing
- Image caching logic
- Favorites management

### Integration Tests
- Scryfall API interaction
- Full application flow
- Error handling scenarios

### Device Testing
- Performance on actual Pi hardware
- Touch interaction testing
- Display quality validation
- Network condition testing 
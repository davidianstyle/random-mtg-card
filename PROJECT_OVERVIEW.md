# Random MTG Card Display - Project Overview

## Project Purpose
A full-screen application for Raspberry Pi with 7" Waveshare display (1024x600) that displays random Magic: The Gathering cards from Scryfall API.

## Technical Requirements

### Hardware Specifications
- **Device**: Raspberry Pi (ARM architecture)
- **Display**: 7" Waveshare touchscreen (600x1024 portrait resolution)
- **Interaction**: Gesture-based, maximized card display
- **Network**: WiFi connection for API calls

### Core Features
1. **Random Card Display**: Fetch and display random MTG cards from Scryfall API
2. **Full-Screen Mode**: Utilize entire 600x1024 display area (portrait)
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

## Framework Recommendations

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

**Ideal if**: You want rapid development and don't mind resource overhead

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

**Ideal if**: You prioritize simplicity and performance over aesthetics

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

**Ideal if**: Touch interaction is primary concern

### 4. **Flutter**
**Best for**: Modern, performant cross-platform UI

**Pros:**
- Excellent performance on ARM
- Beautiful, modern UI out of the box
- Great touch handling
- Good full-screen support
- Strong HTTP client for API calls

**Cons:**
- Larger app size
- Learning curve if new to Dart
- Less established on Pi Linux

**Ideal if**: You want modern UI with good performance

### 5. **Web App (HTML/CSS/JS) + Kiosk Mode**
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

**Ideal if**: You want maximum simplicity and easy testing

## Recommended Architecture

```
┌─────────────────────┐
│   Configuration     │
│   (JSON/YAML)       │
└─────────────────────┘
           │
┌─────────────────────┐
│   Main App          │
│   - State Management│
│   - UI Controller   │
└─────────────────────┘
           │
┌─────────────────────┐    ┌─────────────────────┐
│   Scryfall API      │    │   Local Storage     │
│   Client            │    │   (Favorites)       │
└─────────────────────┘    └─────────────────────┘
           │
┌─────────────────────┐
│   Display Manager   │
│   - Full-screen     │
│   - Touch Events    │
└─────────────────────┘
```

## My Top Recommendation

**Python + Kivy** for the following reasons:
1. **Perfect for Pi**: Lightweight, optimized for ARM
2. **Touch-first**: Built specifically for touch interfaces
3. **Full-screen ready**: Natural full-screen support
4. **Extensible**: Easy to add configuration options
5. **Good performance**: Compiled components where needed
6. **Image handling**: Good support for displaying card images

Would you like me to proceed with setting up the project structure for any of these options, or do you have questions about any specific approach? 
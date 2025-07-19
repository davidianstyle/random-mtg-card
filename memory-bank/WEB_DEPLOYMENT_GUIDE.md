# Web Deployment Guide - MTG Card Display

## Quick Start

### Prerequisites
- Flutter SDK installed with web support enabled
- Modern web browser (Chrome 84+, Firefox 79+, Safari 14+, Edge 84+)
- Python 3 (for local serving) or web server access

### Build and Deploy (5 minutes)
```bash
# 1. Enable web support (if not already done)
flutter config --enable-web

# 2. Add web platform files (if not already done)
flutter create . --platform web

# 3. Build for web
flutter build web --release

# 4. Serve locally
cd build/web
python3 -m http.server 8080

# 5. Open browser
# Navigate to: http://localhost:8080
```

## Platform Comparison

| Feature | Raspberry Pi Native | Web Browser |
|---------|-------------------|-------------|
| **Performance** | Native speed | Good (WebAssembly) |
| **File Caching** | ✅ Full disk cache | ❌ Memory only |
| **File Logging** | ✅ Log files | ❌ Console only |
| **OpenGL Issues** | ❌ May fail on Pi | ✅ No issues |
| **Installation** | Native app install | ❌ No installation needed |
| **Remote Access** | ❌ Local only | ✅ Network accessible |
| **Auto Updates** | Manual rebuild | ✅ Refresh browser |

## Deployment Scenarios

### 1. Raspberry Pi Local Web Server

**Use Case**: Pi with OpenGL issues, want local web access

```bash
# On Raspberry Pi
git clone <your-repo>
cd random-mtg-card
flutter build web --release

# Start web server
cd build/web
python3 -m http.server 8080

# Access from Pi browser: http://localhost:8080
# Access from network: http://pi-ip-address:8080
```

**Benefits**:
- Solves Pi OpenGL context errors
- Access from other devices on network
- No native app installation needed
- Same Pi hardware, different deployment

### 2. Cloud Static Hosting

**Use Case**: Global access, high availability, CDN benefits

#### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize project
firebase init hosting
# Select build/web as public directory
# Configure as single-page app: Yes
# Set up automatic builds: Optional

# Deploy
firebase deploy --only hosting
```

#### Netlify Deploy
```bash
# Option 1: Drag and drop build/web folder to netlify.com
# Option 2: Connect to Git repository
# Build command: flutter build web --release
# Publish directory: build/web
```

#### Vercel Deploy
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy from project root
vercel --build-env FLUTTER_WEB=true
# Build command will be: flutter build web --release
# Output directory: build/web
```

#### GitHub Pages
```bash
# Build locally
flutter build web --release

# Copy build/web contents to gh-pages branch
# OR use GitHub Actions for automatic deployment
```

### 3. Docker Container

**Use Case**: Containerized deployment, consistent environment

```dockerfile
# Dockerfile
FROM nginx:alpine

# Copy Flutter web build
COPY build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        # Flutter web routing
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

```bash
# Build and run container
docker build -t mtg-card-display .
docker run -p 8080:80 mtg-card-display
```

### 4. Apache/Nginx Static Hosting

**Use Case**: Traditional web server deployment

#### Apache Configuration
```apache
<VirtualHost *:80>
    DocumentRoot /var/www/mtg-card-display
    
    # Flutter web routing support
    <Directory /var/www/mtg-card-display>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Fallback to index.html for SPA routing
        FallbackResource /index.html
    </Directory>
    
    # Gzip compression
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/plain
        AddOutputFilterByType DEFLATE text/html
        AddOutputFilterByType DEFLATE text/css
        AddOutputFilterByType DEFLATE application/javascript
        AddOutputFilterByType DEFLATE application/json
    </IfModule>
    
    # Cache static assets
    <IfModule mod_expires.c>
        ExpiresActive on
        ExpiresByType text/css "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/jpg "access plus 1 year"
    </IfModule>
</VirtualHost>
```

#### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/mtg-card-display;
    index index.html;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/css application/javascript application/json;
    
    # Flutter web routing
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

## Build Optimization

### Production Build
```bash
# Standard production build
flutter build web --release

# Optimized build with additional flags
flutter build web --release \
    --web-renderer canvaskit \
    --dart-define=FLUTTER_WEB_USE_SKIA=true \
    --dart-define=FLUTTER_WEB_AUTO_DETECT=false
```

### Build Artifacts
After `flutter build web --release`, you'll have:

```
build/web/
├── index.html              # Entry point
├── main.dart.js           # Compiled Dart code (2-3MB)
├── main.dart.js.map       # Source map (optional)
├── manifest.json          # PWA manifest
├── flutter_service_worker.js # Service worker
├── canvaskit/             # Flutter web engine
├── icons/                 # App icons
├── assets/                # App assets
│   ├── fonts/
│   ├── packages/
│   └── AssetManifest.json
└── version.json           # Version info
```

### Size Optimization
```bash
# Tree-shake icons to reduce size
flutter build web --release --tree-shake-icons

# Split defer loading for better performance
flutter build web --release --split-debug-info=build/web/debug

# Profile build for size analysis
flutter build web --profile --analyze-size
```

## Performance Considerations

### Loading Performance
- **Initial Load**: ~2-3MB compressed (CanvasKit engine)
- **Time to Interactive**: 2-3 seconds on good connections
- **Progressive Loading**: Flutter shows splash screen while loading

### Runtime Performance
- **Frame Rate**: 60 FPS on modern browsers
- **Memory Usage**: ~50-100MB (browser manages memory)
- **Network**: Only API calls and image loading after initial load

### Browser Compatibility
| Browser | Version | Support Level |
|---------|---------|---------------|
| Chrome | 84+ | ✅ Full support |
| Firefox | 79+ | ✅ Full support |
| Safari | 14+ | ✅ Full support |
| Edge | 84+ | ✅ Full support |
| Chrome Mobile | 84+ | ✅ Full support |
| iOS Safari | 14+ | ✅ Full support |

## Monitoring and Analytics

### Performance Monitoring
```dart
// Built-in performance metrics still work
final result = await timeAsync('apiCall', () async {
  return scryfallService.getRandomCardResult();
});
```

### Error Tracking
```javascript
// Add to index.html for error tracking
window.addEventListener('error', function(e) {
  console.error('Flutter Web Error:', e.error);
  // Send to your error tracking service
});
```

### User Analytics
```html
<!-- Add Google Analytics to index.html -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

## Security Considerations

### Content Security Policy
```html
<!-- Add to index.html -->
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline' 'unsafe-eval'; 
               style-src 'self' 'unsafe-inline';
               img-src 'self' https://cards.scryfall.io data:;
               connect-src 'self' https://api.scryfall.com;">
```

### HTTPS Deployment
```bash
# Always deploy with HTTPS in production
# Use Let's Encrypt for free certificates
certbot --nginx -d your-domain.com
```

### API Security
- Scryfall API is CORS-enabled for browser requests
- No API keys required (public API)
- Rate limiting handled by Scryfall
- All requests use HTTPS

## Troubleshooting

### Common Issues

#### Build Fails
```bash
# Clear Flutter caches
flutter clean
flutter pub get

# Rebuild web components
flutter create . --platform web
flutter build web --release
```

#### Large Bundle Size
```bash
# Analyze bundle size
flutter build web --release --analyze-size

# Enable tree-shaking
flutter build web --release --tree-shake-icons

# Check for unused dependencies
flutter deps
```

#### Performance Issues
- **Slow Loading**: Use CDN, enable gzip compression
- **High Memory**: Browser manages memory, no action needed  
- **Slow API Calls**: Same as desktop version, check network

#### CORS Errors
- Scryfall API supports CORS by default
- If using proxy, ensure CORS headers are set
- Check browser console for specific CORS errors

### Debug Mode
```bash
# Run in debug mode with hot reload
flutter run -d web-server --web-port 8080

# Profile mode for performance testing
flutter run --profile -d web-server --web-port 8080
```

## Comparison with Native Deployment

### When to Use Web Deployment

✅ **Use Web When**:
- Raspberry Pi has OpenGL/graphics driver issues
- Want remote access from other devices
- Need zero-installation deployment
- Want easy updates (just refresh browser)
- Testing/development on non-Pi machines
- Deploying to multiple Pis easily

❌ **Use Native When**:
- Maximum performance is critical
- Need file system caching for offline use
- Want persistent file logging
- Have stable OpenGL drivers
- Single-device dedicated kiosk setup

### Migration Strategy

1. **Test Both**: Try native first, fallback to web
2. **Gradual Migration**: Use web for development, native for production
3. **Hybrid Approach**: Native primary, web backup
4. **Full Web**: If native consistently fails

This web deployment strategy provides a robust fallback for Pi deployment issues while maintaining all core functionality and architectural benefits. 
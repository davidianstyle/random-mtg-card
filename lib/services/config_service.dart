import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance!;
  
  late SharedPreferences _prefs;
  
  // Configuration keys
  static const String _configKey = 'app_config';
  
  // Default configuration
  static const Map<String, dynamic> _defaultConfig = {
    'display': {
      'fullscreen': true,
      'resolution': [600, 1024],
      'orientation': 'portrait',
      'auto_refresh_interval': 30,
      'show_metadata_on_tap': true,
      'metadata_auto_hide_delay': 3,
    },
    'filters': {
      'enabled': false,
      'sets': <String>[],
      'colors': <String>[],
      'types': <String>[],
      'rarity': <String>[],
      'format': 'standard',
    },
    'features': {
      'favorites': true,
      'favorite_indicator': true,
      'swipe_navigation': true,
      'double_tap_favorite': true,
      'tap_metadata_toggle': true,
      'long_press_details': true,
      'offline_mode': false,
    },
    'api': {
      'base_url': 'https://api.scryfall.com',
      'timeout': 10,
      'retry_attempts': 3,
      'cache_images': true,
    },
  };
  
  static Future<void> initialize() async {
    _instance = ConfigService();
    _instance!._prefs = await SharedPreferences.getInstance();
  }
  
  /// Get the full configuration
  Map<String, dynamic> get config {
    final configJson = _prefs.getString(_configKey);
    if (configJson != null) {
      try {
        final savedConfig = jsonDecode(configJson) as Map<String, dynamic>;
        return _mergeConfigs(_defaultConfig, savedConfig);
      } catch (e) {
        print('Error loading config: $e');
        return _defaultConfig;
      }
    }
    return _defaultConfig;
  }
  
  /// Save configuration
  Future<void> saveConfig(Map<String, dynamic> config) async {
    final configJson = jsonEncode(config);
    await _prefs.setString(_configKey, configJson);
  }
  
  /// Update a specific configuration value
  Future<void> updateConfig(String path, dynamic value) async {
    final currentConfig = config;
    _setNestedValue(currentConfig, path, value);
    await saveConfig(currentConfig);
  }
  
  /// Get a specific configuration value
  T getValue<T>(String path, T defaultValue) {
    final currentConfig = config;
    return _getNestedValue(currentConfig, path, defaultValue);
  }
  
  // Display settings
  bool get fullscreen => getValue('display.fullscreen', true);
  List<int> get resolution => List<int>.from(getValue('display.resolution', [600, 1024]));
  String get orientation => getValue('display.orientation', 'portrait');
  int get autoRefreshInterval => getValue('display.auto_refresh_interval', 30);
  bool get showMetadataOnTap => getValue('display.show_metadata_on_tap', true);
  int get metadataAutoHideDelay => getValue('display.metadata_auto_hide_delay', 3);
  
  // Filter settings
  bool get filtersEnabled => getValue('filters.enabled', false);
  List<String> get filterSets => List<String>.from(getValue('filters.sets', <String>[]));
  List<String> get filterColors => List<String>.from(getValue('filters.colors', <String>[]));
  List<String> get filterTypes => List<String>.from(getValue('filters.types', <String>[]));
  List<String> get filterRarity => List<String>.from(getValue('filters.rarity', <String>[]));
  String get filterFormat => getValue('filters.format', 'standard');
  
  // Feature settings
  bool get favoritesEnabled => getValue('features.favorites', true);
  bool get favoriteIndicator => getValue('features.favorite_indicator', true);
  bool get swipeNavigation => getValue('features.swipe_navigation', true);
  bool get doubleTapFavorite => getValue('features.double_tap_favorite', true);
  bool get tapMetadataToggle => getValue('features.tap_metadata_toggle', true);
  bool get longPressDetails => getValue('features.long_press_details', true);
  bool get offlineMode => getValue('features.offline_mode', false);
  
  // API settings
  String get apiBaseUrl => getValue('api.base_url', 'https://api.scryfall.com');
  int get apiTimeout => getValue('api.timeout', 10);
  int get retryAttempts => getValue('api.retry_attempts', 3);
  bool get cacheImages => getValue('api.cache_images', true);
  
  /// Merge two configuration maps, with saved values taking precedence
  Map<String, dynamic> _mergeConfigs(Map<String, dynamic> defaults, Map<String, dynamic> saved) {
    final merged = Map<String, dynamic>.from(defaults);
    
    saved.forEach((key, value) {
      if (merged[key] is Map<String, dynamic> && value is Map<String, dynamic>) {
        merged[key] = _mergeConfigs(merged[key], value);
      } else {
        merged[key] = value;
      }
    });
    
    return merged;
  }
  
  /// Get a nested value from a configuration map
  T _getNestedValue<T>(Map<String, dynamic> config, String path, T defaultValue) {
    final parts = path.split('.');
    dynamic current = config;
    
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return defaultValue;
      }
    }
    
    return current is T ? current : defaultValue;
  }
  
  /// Set a nested value in a configuration map
  void _setNestedValue(Map<String, dynamic> config, String path, dynamic value) {
    final parts = path.split('.');
    Map<String, dynamic> current = config;
    
    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (!current.containsKey(part) || current[part] is! Map<String, dynamic>) {
        current[part] = <String, dynamic>{};
      }
      current = current[part] as Map<String, dynamic>;
    }
    
    current[parts.last] = value;
  }
  
  /// Reset configuration to defaults
  Future<void> resetToDefaults() async {
    await saveConfig(_defaultConfig);
  }
} 
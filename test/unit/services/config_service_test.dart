import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_mtg_card/services/config_service.dart';

// Helper function to suppress debug output during tests
Future<void> runWithoutDebugOutput(Future<void> Function() callback) async {
  final originalPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    // Suppress debug output during tests
  };

  try {
    await callback();
  } finally {
    debugPrint = originalPrint;
  }
}

void main() {
  group('ConfigService', () {
    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clean up after each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize with default configuration', () async {
        // Act
        await ConfigService.initialize();

        // Assert
        expect(ConfigService.instance, isA<ConfigService>());
        final config = ConfigService.instance.config;
        expect(config, isA<Map<String, dynamic>>());

        // Check default values
        expect(config['display']['fullscreen'], equals(true));
        expect(config['display']['resolution'], equals([600, 1024]));
        expect(config['display']['orientation'], equals('portrait'));
        expect(config['features']['favorites'], equals(true));
        expect(config['features']['swipe_navigation'], equals(true));
        expect(config['api']['base_url'], equals('https://api.scryfall.com'));
      });

      test('should be a singleton', () async {
        // Act
        await ConfigService.initialize();
        final instance1 = ConfigService.instance;
        final instance2 = ConfigService.instance;

        // Assert
        expect(instance1, same(instance2));
      });
    });

    group('Configuration Management', () {
      test('should load saved configuration', () async {
        // Arrange
        final savedConfig = {
          'display': {
            'fullscreen': false,
            'resolution': [800, 600],
            'orientation': 'landscape',
          },
          'features': {
            'favorites': false,
            'swipe_navigation': false,
          },
        };

        SharedPreferences.setMockInitialValues({
          'app_config': jsonEncode(savedConfig),
        });

        // Act
        await ConfigService.initialize();
        final config = ConfigService.instance.config;

        // Assert
        expect(config['display']['fullscreen'], equals(false));
        expect(config['display']['resolution'], equals([800, 600]));
        expect(config['display']['orientation'], equals('landscape'));
        expect(config['features']['favorites'], equals(false));
        expect(config['features']['swipe_navigation'], equals(false));
      });

      test('should merge saved config with defaults', () async {
        // Arrange
        final partialConfig = {
          'display': {
            'fullscreen': false,
          },
        };

        SharedPreferences.setMockInitialValues({
          'app_config': jsonEncode(partialConfig),
        });

        // Act
        await ConfigService.initialize();
        final config = ConfigService.instance.config;

        // Assert
        // Should have the saved value
        expect(config['display']['fullscreen'], equals(false));
        // Should have default values for missing keys
        expect(config['display']['resolution'], equals([600, 1024]));
        expect(config['display']['orientation'], equals('portrait'));
        expect(config['features']['favorites'], equals(true));
      });

      test('should save configuration', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        final newConfig = {
          'display': {
            'fullscreen': false,
            'resolution': [1920, 1080],
            'orientation': 'landscape',
          },
          'features': {
            'favorites': true,
            'swipe_navigation': false,
          },
        };

        // Act
        await service.saveConfig(newConfig);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final savedJson = prefs.getString('app_config');
        expect(savedJson, isNotNull);

        final savedConfig = jsonDecode(savedJson!);
        expect(savedConfig['display']['fullscreen'], equals(false));
        expect(savedConfig['display']['resolution'], equals([1920, 1080]));
        expect(savedConfig['features']['swipe_navigation'], equals(false));
      });

      test('should handle invalid JSON gracefully', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'app_config': 'invalid json',
        });

        // Act & Assert - suppress debug print output during test
        await runWithoutDebugOutput(() async {
          expect(() async => await ConfigService.initialize(), returnsNormally);
          await ConfigService.initialize();
        });

        final config = ConfigService.instance.config;

        // Should fall back to defaults
        expect(config['display']['fullscreen'], equals(true));
        expect(config['display']['resolution'], equals([600, 1024]));
      });
    });

    group('Display Configuration', () {
      test('should provide display settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final config = service.config;
        final displayConfig = config['display'] as Map<String, dynamic>;

        // Assert
        expect(displayConfig['fullscreen'], isA<bool>());
        expect(displayConfig['resolution'], isA<List>());
        expect(displayConfig['orientation'], isA<String>());
        expect(displayConfig['auto_refresh_interval'], isA<int>());
        expect(displayConfig['show_metadata_on_tap'], isA<bool>());
        expect(displayConfig['metadata_auto_hide_delay'], isA<int>());
      });

      test('should allow updating display settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final newConfig = {
          'display': {
            'fullscreen': false,
            'resolution': [1920, 1080],
            'orientation': 'landscape',
            'auto_refresh_interval': 60,
            'show_metadata_on_tap': false,
            'metadata_auto_hide_delay': 5,
          },
        };

        await service.saveConfig(newConfig);

        // Assert
        final config = service.config;
        final displayConfig = config['display'] as Map<String, dynamic>;
        expect(displayConfig['fullscreen'], equals(false));
        expect(displayConfig['resolution'], equals([1920, 1080]));
        expect(displayConfig['orientation'], equals('landscape'));
        expect(displayConfig['auto_refresh_interval'], equals(60));
        expect(displayConfig['show_metadata_on_tap'], equals(false));
        expect(displayConfig['metadata_auto_hide_delay'], equals(5));
      });
    });

    group('Filter Configuration', () {
      test('should provide filter settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final config = service.config;
        final filterConfig = config['filters'] as Map<String, dynamic>;

        // Assert
        expect(filterConfig['enabled'], isA<bool>());
        expect(filterConfig['sets'], isA<List>());
        expect(filterConfig['colors'], isA<List>());
        expect(filterConfig['card_types'], isA<List>());
        expect(filterConfig['rarity'], isA<List>());
        expect(filterConfig['format'], isA<String>());
      });

      test('should allow updating filter settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final newConfig = {
          'filters': {
            'enabled': true,
            'sets': ['lea', 'leb', 'leu'],
            'colors': ['R', 'U'],
            'types': ['Instant', 'Sorcery'],
            'rarity': ['rare', 'mythic'],
            'format': 'vintage',
          },
        };

        await service.saveConfig(newConfig);

        // Assert
        final config = service.config;
        final filterConfig = config['filters'] as Map<String, dynamic>;
        expect(filterConfig['enabled'], equals(true));
        expect(filterConfig['sets'], equals(['lea', 'leb', 'leu']));
        expect(filterConfig['colors'], equals(['R', 'U']));
        expect(filterConfig['types'], equals(['Instant', 'Sorcery']));
        expect(filterConfig['rarity'], equals(['rare', 'mythic']));
        expect(filterConfig['format'], equals('vintage'));
      });
    });

    group('Feature Configuration', () {
      test('should provide feature settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final config = service.config;
        final featureConfig = config['features'] as Map<String, dynamic>;

        // Assert
        expect(featureConfig['favorites'], isA<bool>());
        expect(featureConfig['favorite_indicator'], isA<bool>());
        expect(featureConfig['swipe_navigation'], isA<bool>());
        expect(featureConfig['double_tap_favorite'], isA<bool>());
        expect(featureConfig['tap_metadata_toggle'], isA<bool>());
        expect(featureConfig['long_press_details'], isA<bool>());
        expect(featureConfig['offline_mode'], isA<bool>());
      });

      test('should allow updating feature settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final newConfig = {
          'features': {
            'favorites': false,
            'favorite_indicator': false,
            'swipe_navigation': true,
            'double_tap_favorite': false,
            'tap_metadata_toggle': true,
            'long_press_details': false,
            'offline_mode': true,
          },
        };

        await service.saveConfig(newConfig);

        // Assert
        final config = service.config;
        final featureConfig = config['features'] as Map<String, dynamic>;
        expect(featureConfig['favorites'], equals(false));
        expect(featureConfig['favorite_indicator'], equals(false));
        expect(featureConfig['swipe_navigation'], equals(true));
        expect(featureConfig['double_tap_favorite'], equals(false));
        expect(featureConfig['tap_metadata_toggle'], equals(true));
        expect(featureConfig['long_press_details'], equals(false));
        expect(featureConfig['offline_mode'], equals(true));
      });
    });

    group('API Configuration', () {
      test('should provide API settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final config = service.config;
        final apiConfig = config['api'] as Map<String, dynamic>;

        // Assert
        expect(apiConfig['base_url'], isA<String>());
        expect(apiConfig['timeout'], isA<int>());
        expect(apiConfig['retry_attempts'], isA<int>());
        expect(apiConfig['cache_images'], isA<bool>());
      });

      test('should allow updating API settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // Act
        final newConfig = {
          'api': {
            'base_url': 'https://custom.api.com',
            'timeout': 30,
            'retry_attempts': 5,
            'cache_images': false,
          },
        };

        await service.saveConfig(newConfig);

        // Assert
        final config = service.config;
        final apiConfig = config['api'] as Map<String, dynamic>;
        expect(apiConfig['base_url'], equals('https://custom.api.com'));
        expect(apiConfig['timeout'], equals(30));
        expect(apiConfig['retry_attempts'], equals(5));
        expect(apiConfig['cache_images'], equals(false));
      });
    });

    group('Configuration Persistence', () {
      test('should persist configuration across sessions', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        final newConfig = {
          'display': {
            'fullscreen': false,
            'resolution': [1920, 1080],
          },
          'features': {
            'favorites': false,
          },
        };

        // Act
        await service.saveConfig(newConfig);

        // Simulate new session
        await ConfigService.initialize();
        final newService = ConfigService.instance;
        final persistedConfig = newService.config;

        // Assert
        expect(persistedConfig['display']['fullscreen'], equals(false));
        expect(persistedConfig['display']['resolution'], equals([1920, 1080]));
        expect(persistedConfig['features']['favorites'], equals(false));
      });

      test('should handle configuration corruption', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({
          'app_config': '{"invalid": json}',
        });

        // Act & Assert - suppress debug print output during test
        await runWithoutDebugOutput(() async {
          expect(() async => await ConfigService.initialize(), returnsNormally);
          await ConfigService.initialize();
        });

        final config = ConfigService.instance.config;

        // Should fall back to defaults
        expect(config['display']['fullscreen'], equals(true));
        expect(config['features']['favorites'], equals(true));
      });
    });

    group('Helper Methods', () {
      test('should provide convenient access to common settings', () async {
        // Arrange
        await ConfigService.initialize();
        final service = ConfigService.instance;

        // This would test any convenience methods that might be added
        // For example, if the service had methods like:
        // - service.isFullscreen
        // - service.displayResolution
        // - service.apiBaseUrl

        // Act
        final config = service.config;

        // Assert
        expect(config, isA<Map<String, dynamic>>());
        expect(config['display'], isA<Map<String, dynamic>>());
        expect(config['features'], isA<Map<String, dynamic>>());
        expect(config['api'], isA<Map<String, dynamic>>());
      });
    });
  });
}

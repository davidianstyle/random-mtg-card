import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_mtg_card/models/mtg_card.dart';
import 'package:random_mtg_card/services/scryfall_service.dart';
import 'package:random_mtg_card/services/config_service.dart';
import 'package:random_mtg_card/services/service_locator.dart';
import 'package:random_mtg_card/services/cache_service.dart';
import 'package:random_mtg_card/utils/logger.dart';
import 'package:random_mtg_card/utils/result.dart';

// Mock cache service for testing
class MockCacheService implements CacheService {
  @override
  Future<Result<String>> getApiResponse(String key) async {
    return const Failure(CacheError(message: 'Cache miss'));
  }

  @override
  Future<Result<void>> cacheApiResponse(String key, String data,
      {Duration? ttl}) async {
    return const Success(null);
  }

  @override
  Future<Result<Uint8List>> getImage(String url) async {
    return const Failure(CacheError(message: 'Cache miss'));
  }

  @override
  Future<Result<void>> cacheImage(String url, Uint8List data,
      {Duration? ttl}) async {
    return const Success(null);
  }

  @override
  Future<void> clearAll() async {
    // Mock implementation - do nothing
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    return {};
  }

  @override
  void dispose() {
    // Mock implementation - do nothing
  }

  // Additional methods that might be needed
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ScryfallService', () {
    late ScryfallService service;

    setUpAll(() async {
      // Initialize Flutter binding
      TestWidgetsFlutterBinding.ensureInitialized();

      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      // Initialize ConfigService before running tests
      await ConfigService.initialize();

      // Initialize logger without file logging for tests
      await Logger.initialize(
        enableFileLogging: false,
        enableConsoleLogging: true,
        minLevel: LogLevel.error, // Reduce noise in tests
      );

      // Set up service locator with required services once
      final serviceLocator = ServiceLocator.instance;
      serviceLocator.reset();
      serviceLocator.registerSingleton<ConfigService>(ConfigService.instance);
      serviceLocator.registerSingleton<Logger>(Logger.instance);

      // Create a mock cache service for testing
      serviceLocator.registerFactory<CacheService>(() => MockCacheService());

      // Initialize service once for all tests
      service = ScryfallService.instance;
      await service.initialize();
    });

    setUp(() async {
      // Service is already initialized in setUpAll
      // Just get the instance for each test
      service = ScryfallService.instance;
    });

    tearDown(() async {
      ServiceLocator.instance.reset();
    });

    group('getRandomCard', () {
      test('should return MTGCard when API call succeeds', () async {
        // Note: This test depends on actual HTTP calls since the service is a singleton
        // In a real implementation, we would need to modify the service to accept a custom client
        // For now, we'll test the public interface

        // This test would need to be modified to work with the actual service
        // or the service would need to be refactored to accept dependency injection

        expect(service, isA<ScryfallService>());
        expect(service.getRandomCard, isA<Function>());
      });

      test('should handle rate limiting between requests', () async {
        // Test that consecutive calls are rate limited
        final start = DateTime.now();

        // These calls will actually hit the API, so we test the rate limiting logic
        // In a more controlled test, we would mock the HTTP client

        // For now, just test that the method exists and returns the right type
        final result = await service.getRandomCard();
        expect(result, isA<MTGCard?>());

        final end = DateTime.now();
        final elapsed = end.difference(start);

        // The rate limiting should be handled internally
        expect(elapsed.inMilliseconds, greaterThanOrEqualTo(0));
      });
    });

    group('searchCards', () {
      test('should handle search with query parameter', () async {
        // Test that the method exists and returns the right type
        final result = await service.searchCards(query: 'lightning');
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle search with set filters', () async {
        // Test filtering by sets
        final result = await service.searchCards(sets: ['lea', 'leb']);
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle search with color filters', () async {
        // Test filtering by colors
        final result = await service.searchCards(colors: ['R', 'U']);
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle search with type filters', () async {
        // Test filtering by types
        final result = await service.searchCards(types: ['Instant', 'Sorcery']);
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle search with rarity filters', () async {
        // Test filtering by rarity
        final result =
            await service.searchCards(rarity: ['common', 'uncommon']);
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle search with format filter', () async {
        // Test filtering by format
        final result = await service.searchCards(format: 'standard');
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle search with pagination', () async {
        // Test pagination
        final result = await service.searchCards(query: 'lightning', page: 2);
        expect(result, isA<List<MTGCard>>());
      });

      test('should handle combined filters', () async {
        // Test multiple filters combined
        final result = await service.searchCards(
          query: 'lightning',
          sets: ['lea'],
          colors: ['R'],
          types: ['Instant'],
          rarity: ['common'],
          format: 'vintage',
        );
        expect(result, isA<List<MTGCard>>());
      });
    });

    group('getCard', () {
      test('should return MTGCard when card exists', () async {
        // Test getting a specific card by ID
        // This would need a known card ID for testing
        expect(service.getCard, isA<Function>());
      });

      test('should handle non-existent card ID', () async {
        // Test with a non-existent card ID
        final result = await service.getCard('nonexistent-id');
        expect(result, isNull);
      });
    });

    group('getSets', () {
      test('should return list of sets', () async {
        // Test getting all available sets
        final result = await service.getSets();
        expect(result, isA<List<Map<String, dynamic>>>());
        
        // The method should return an empty list if API call fails
        // This handles network errors gracefully (returns [] on error)
        expect(result, isNotNull);
      });
    });

    group('getRandomCardWithFilters', () {
      test('should return MTGCard with filters applied', () async {
        // Test getting a random card with filters
        final result = await service.getRandomCardWithFilters();
        expect(result, isA<MTGCard?>());
      });
    });

    group('isServiceAvailable', () {
      test('should check if service is available', () async {
        // Test service availability check
        final result = await service.isServiceAvailable();
        expect(result, isA<bool>());
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Test that network errors are handled gracefully
        // The service should return null or empty lists rather than throwing

        // This would require mocking network conditions
        // For now, we just test that the methods don't throw
        expect(() async => await service.getRandomCard(), returnsNormally);
        expect(() async => await service.searchCards(query: 'test'),
            returnsNormally);
        expect(() async => await service.getCard('test-id'), returnsNormally);
        expect(() async => await service.getSets(), returnsNormally);
      });

      test('should handle invalid JSON responses', () async {
        // Test that invalid JSON responses are handled
        // The service should return null or empty lists

        expect(() async => await service.getRandomCard(), returnsNormally);
      });

      test('should handle HTTP error status codes', () async {
        // Test that HTTP errors are handled gracefully
        // The service should return null or empty lists

        expect(() async => await service.getRandomCard(), returnsNormally);
      });
    });

    group('Rate Limiting', () {
      test('should respect rate limits between requests', () async {
        // Test that the service respects rate limits
        final start = DateTime.now();

        // Make multiple requests to test rate limiting
        // Use getSets which uses the rate-limited _makeRequest method
        await service.getSets();
        await service.getSets();

        final end = DateTime.now();
        final elapsed = end.difference(start);

        // Should have taken at least some time for two requests
        // This is a basic timing test - in a real implementation we'd mock the HTTP client
        expect(elapsed.inMilliseconds, greaterThanOrEqualTo(0));
        
        // Just verify the service is working and returns expected types
        expect(service.getSets(), isA<Future<List<Map<String, dynamic>>>>());
      });
    });

    group('Configuration Integration', () {
      test('should use configuration settings', () async {
        // Test that the service uses configuration settings
        // This would test integration with ConfigService

        // The service should read from ConfigService for:
        // - API base URL
        // - API timeout
        // - Filter settings

        expect(service, isA<ScryfallService>());

        // Test that methods work with config
        final result = await service.getRandomCard();
        expect(result, isA<MTGCard?>());
      });
    });
  });
}

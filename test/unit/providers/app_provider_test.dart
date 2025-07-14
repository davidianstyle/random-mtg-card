import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_mtg_card/models/mtg_card.dart';
import 'package:random_mtg_card/providers/app_provider.dart';
import 'package:random_mtg_card/services/config_service.dart';

void main() {
  group('AppProvider', () {
    late AppProvider provider;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      await ConfigService.initialize();
      provider = AppProvider();
      await provider.initialize();
    });

    tearDown(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize with default values', () async {
        // Arrange
        final newProvider = AppProvider();

        // Act
        await newProvider.initialize();

        // Assert
        expect(newProvider.favoriteCardIds, isEmpty);
        expect(newProvider.favoriteCards, isEmpty);
        expect(newProvider.showMetadata, isFalse);
        expect(newProvider.isLoading, isFalse);
        expect(newProvider.errorMessage, isNull);
      });

      test('should load existing favorites on initialization', () async {
        // Arrange
        final existingFavorites = ['card-1', 'card-2', 'card-3'];
        final favoritesJson = jsonEncode(existingFavorites
            .map((id) => {
                  'id': id,
                  'added_date': DateTime.now().toIso8601String(),
                })
            .toList());

        SharedPreferences.setMockInitialValues({
          'favorites': favoritesJson,
        });

        final newProvider = AppProvider();

        // Act
        await newProvider.initialize();

        // Assert
        expect(newProvider.favoriteCardIds, equals(existingFavorites));
      });
    });

    group('Favorites Management', () {
      test('should add card to favorites', () async {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        // Act
        await provider.addFavorite(card);

        // Assert
        expect(provider.favoriteCardIds, contains('test-card-1'));
        expect(provider.favoriteCards, contains(card));
        expect(provider.isFavorite('test-card-1'), isTrue);
      });

      test('should remove card from favorites', () async {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        await provider.addFavorite(card);
        expect(provider.isFavorite('test-card-1'), isTrue);

        // Act
        await provider.removeFavorite('test-card-1');

        // Assert
        expect(provider.favoriteCardIds, isNot(contains('test-card-1')));
        expect(provider.favoriteCards, isNot(contains(card)));
        expect(provider.isFavorite('test-card-1'), isFalse);
      });

      test('should toggle favorite status', () async {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        expect(provider.isFavorite('test-card-1'), isFalse);

        // Act - Add to favorites
        await provider.toggleFavorite(card);

        // Assert
        expect(provider.isFavorite('test-card-1'), isTrue);
        expect(provider.favoriteCards, contains(card));

        // Act - Remove from favorites
        await provider.toggleFavorite(card);

        // Assert
        expect(provider.isFavorite('test-card-1'), isFalse);
        expect(provider.favoriteCards, isNot(contains(card)));
      });

      test('should not add duplicate favorites', () async {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        // Act
        await provider.addFavorite(card);
        await provider.addFavorite(card);

        // Assert
        expect(provider.favoriteCardIds.length, equals(1));
        expect(provider.favoriteCards.length, equals(1));
      });

      test('should clear all favorites', () async {
        // Arrange
        final card1 = MTGCard(
          id: 'test-card-1',
          name: 'Test Card 1',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        final card2 = MTGCard(
          id: 'test-card-2',
          name: 'Test Card 2',
          typeLine: 'Sorcery',
          set: 'test',
          setName: 'Test Set',
          rarity: 'uncommon',
        );

        await provider.addFavorite(card1);
        await provider.addFavorite(card2);
        expect(provider.favoriteCards.length, equals(2));

        // Act
        await provider.clearFavorites();

        // Assert
        expect(provider.favoriteCardIds, isEmpty);
        expect(provider.favoriteCards, isEmpty);
      });

      test('should handle null card ID in isFavorite', () {
        // Act & Assert
        expect(provider.isFavorite(null), isFalse);
        expect(provider.isFavorite(''), isFalse);
      });
    });

    group('Metadata Visibility', () {
      test('should toggle metadata visibility', () {
        // Arrange
        expect(provider.showMetadata, isFalse);

        // Act
        provider.toggleMetadata();

        // Assert
        expect(provider.showMetadata, isTrue);

        // Act
        provider.toggleMetadata();

        // Assert
        expect(provider.showMetadata, isFalse);
      });

      test('should hide metadata', () {
        // Arrange
        provider.toggleMetadata(); // Show metadata first
        expect(provider.showMetadata, isTrue);

        // Act
        provider.hideMetadata();

        // Assert
        expect(provider.showMetadata, isFalse);
      });

      test('should show metadata', () {
        // Arrange
        expect(provider.showMetadata, isFalse);

        // Act
        provider.showMetadataOverlay();

        // Assert
        expect(provider.showMetadata, isTrue);
      });
    });

    group('Loading State', () {
      test('should set loading state', () {
        // Arrange
        expect(provider.isLoading, isFalse);

        // Act
        provider.setLoading(true);

        // Assert
        expect(provider.isLoading, isTrue);

        // Act
        provider.setLoading(false);

        // Assert
        expect(provider.isLoading, isFalse);
      });
    });

    group('Error Handling', () {
      test('should set error message', () {
        // Arrange
        expect(provider.errorMessage, isNull);

        // Act
        provider.setError('Test error message');

        // Assert
        expect(provider.errorMessage, equals('Test error message'));
      });

      test('should clear error message', () {
        // Arrange
        provider.setError('Test error message');
        expect(provider.errorMessage, isNotNull);

        // Act
        provider.clearError();

        // Assert
        expect(provider.errorMessage, isNull);
      });
    });

    group('State Persistence', () {
      test('should persist favorites to SharedPreferences', () async {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        // Act
        await provider.addFavorite(card);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final favoritesJson = prefs.getString('favorites');
        expect(favoritesJson, isNotNull);

        final favoritesList = jsonDecode(favoritesJson!) as List<dynamic>;
        final favoriteIds =
            favoritesList.map((item) => item['id'] as String).toList();
        expect(favoriteIds, contains('test-card-1'));
      });

      test('should load persisted favorites', () async {
        // Arrange
        final favoriteIds = ['card-1', 'card-2'];
        final favoritesJson = jsonEncode(favoriteIds
            .map((id) => {
                  'id': id,
                  'added_date': DateTime.now().toIso8601String(),
                })
            .toList());

        SharedPreferences.setMockInitialValues({
          'favorites': favoritesJson,
        });

        final newProvider = AppProvider();

        // Act
        await newProvider.initialize();

        // Assert
        expect(newProvider.favoriteCardIds, equals(favoriteIds));
      });

      test('should handle missing favorites in SharedPreferences', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        final newProvider = AppProvider();

        // Act
        await newProvider.initialize();

        // Assert
        expect(newProvider.favoriteCardIds, isEmpty);
      });
    });

    group('Change Notifications', () {
      test('should notify listeners when favorites change', () async {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        bool notificationReceived = false;
        provider.addListener(() {
          notificationReceived = true;
        });

        // Act
        await provider.addFavorite(card);

        // Assert
        expect(notificationReceived, isTrue);
      });

      test('should notify listeners when metadata visibility changes', () {
        // Arrange
        bool notificationReceived = false;
        provider.addListener(() {
          notificationReceived = true;
        });

        // Act
        provider.toggleMetadata();

        // Assert
        expect(notificationReceived, isTrue);
      });

      test('should notify listeners when loading state changes', () {
        // Arrange
        bool notificationReceived = false;
        provider.addListener(() {
          notificationReceived = true;
        });

        // Act
        provider.setLoading(true);

        // Assert
        expect(notificationReceived, isTrue);
      });

      test('should notify listeners when error state changes', () {
        // Arrange
        bool notificationReceived = false;
        provider.addListener(() {
          notificationReceived = true;
        });

        // Act
        provider.setError('Test error');

        // Assert
        expect(notificationReceived, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle removing non-existent favorite', () async {
        // Arrange
        expect(provider.favoriteCardIds, isEmpty);

        // Act & Assert
        expect(() async => await provider.removeFavorite('non-existent'),
            returnsNormally);
        expect(provider.favoriteCardIds, isEmpty);
      });

      test('should handle empty favorites list', () {
        // Act & Assert
        expect(provider.favoriteCardIds, isEmpty);
        expect(provider.favoriteCards, isEmpty);
        expect(provider.isFavorite('any-id'), isFalse);
      });

      test('should handle multiple rapid state changes', () {
        // Act
        provider.setLoading(true);
        provider.setLoading(false);
        provider.setError('Error 1');
        provider.setError('Error 2');
        provider.clearError();
        provider.toggleMetadata();
        provider.toggleMetadata();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.showMetadata, isFalse);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_mtg_card/models/mtg_card.dart';
import 'package:random_mtg_card/providers/card_provider.dart';
import 'package:random_mtg_card/services/config_service.dart';

void main() {
  group('CardProvider', () {
    late CardProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ConfigService.initialize();
      provider = CardProvider();
    });

    tearDown(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        // Assert
        expect(provider.currentCard, isNull);
        expect(provider.cardHistory, isEmpty);
        expect(provider.currentIndex, equals(0));
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
      });
    });

    group('Card Management', () {
      test('should set current card', () {
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
        provider.setCurrentCard(card);

        // Assert
        expect(provider.currentCard, equals(card));
        expect(provider.cardHistory, contains(card));
        expect(provider.currentIndex, equals(0));
      });

      test('should add card to history', () {
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

        // Act
        provider.setCurrentCard(card1);
        provider.setCurrentCard(card2);

        // Assert
        expect(provider.cardHistory.length, equals(2));
        expect(provider.cardHistory[0], equals(card1));
        expect(provider.cardHistory[1], equals(card2));
        expect(provider.currentCard, equals(card2));
        expect(provider.currentIndex, equals(1));
      });

      test('should handle null card', () {
        // Act
        provider.setCurrentCard(null);

        // Assert
        expect(provider.currentCard, isNull);
        expect(provider.cardHistory, isEmpty);
        expect(provider.currentIndex, equals(0));
      });
    });

    group('Navigation', () {
      test('should navigate to previous card', () {
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

        provider.setCurrentCard(card1);
        provider.setCurrentCard(card2);
        expect(provider.currentCard, equals(card2));

        // Act
        provider.goToPreviousCard();

        // Assert
        expect(provider.currentCard, equals(card1));
        expect(provider.currentIndex, equals(0));
      });

      test('should navigate to next card', () {
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

        provider.setCurrentCard(card1);
        provider.setCurrentCard(card2);
        provider.goToPreviousCard();
        expect(provider.currentCard, equals(card1));

        // Act
        provider.goToNextCard();

        // Assert
        expect(provider.currentCard, equals(card2));
        expect(provider.currentIndex, equals(1));
      });

      test('should handle previous when at beginning', () {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        provider.setCurrentCard(card);
        expect(provider.currentIndex, equals(0));

        // Act
        provider.goToPreviousCard();

        // Assert
        expect(provider.currentCard, equals(card));
        expect(provider.currentIndex, equals(0));
      });

      test('should handle next when at end', () {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        provider.setCurrentCard(card);
        expect(provider.currentIndex, equals(0));

        // Act
        provider.goToNextCard();

        // Assert
        expect(provider.currentCard, equals(card));
        expect(provider.currentIndex, equals(0));
      });

      test('should check if can go to previous', () {
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

        // Act & Assert
        expect(provider.canGoToPrevious, isFalse);

        provider.setCurrentCard(card1);
        expect(provider.canGoToPrevious, isFalse);

        provider.setCurrentCard(card2);
        expect(provider.canGoToPrevious, isTrue);
      });

      test('should check if can go to next', () {
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

        // Act & Assert
        expect(provider.canGoToNext, isFalse);

        provider.setCurrentCard(card1);
        provider.setCurrentCard(card2);
        expect(provider.canGoToNext, isFalse);

        provider.goToPreviousCard();
        expect(provider.canGoToNext, isTrue);
      });
    });

    group('History Management', () {
      test('should limit history size', () {
        // Arrange
        final maxHistorySize = 50; // Assuming this is the limit

        // Act
        for (int i = 0; i < maxHistorySize + 10; i++) {
          final card = MTGCard(
            id: 'test-card-$i',
            name: 'Test Card $i',
            typeLine: 'Instant',
            set: 'test',
            setName: 'Test Set',
            rarity: 'common',
          );
          provider.setCurrentCard(card);
        }

        // Assert
        expect(provider.cardHistory.length, lessThanOrEqualTo(maxHistorySize));
      });

      test('should clear history', () {
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

        provider.setCurrentCard(card1);
        provider.setCurrentCard(card2);
        expect(provider.cardHistory.length, equals(2));

        // Act
        provider.clearHistory();

        // Assert
        expect(provider.cardHistory, isEmpty);
        expect(provider.currentCard, isNull);
        expect(provider.currentIndex, equals(0));
      });

      test('should maintain history order', () {
        // Arrange
        final cards = List.generate(
            5,
            (i) => MTGCard(
                  id: 'test-card-$i',
                  name: 'Test Card $i',
                  typeLine: 'Instant',
                  set: 'test',
                  setName: 'Test Set',
                  rarity: 'common',
                ));

        // Act
        for (final card in cards) {
          provider.setCurrentCard(card);
        }

        // Assert
        for (int i = 0; i < cards.length; i++) {
          expect(provider.cardHistory[i], equals(cards[i]));
        }
      });
    });

    group('Loading and Error States', () {
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

      test('should set error state', () {
        // Arrange
        expect(provider.errorMessage, isNull);

        // Act
        provider.setError('Test error message');

        // Assert
        expect(provider.errorMessage, equals('Test error message'));
      });

      test('should clear error state', () {
        // Arrange
        provider.setError('Test error message');
        expect(provider.errorMessage, isNotNull);

        // Act
        provider.clearError();

        // Assert
        expect(provider.errorMessage, isNull);
      });
    });

    group('Change Notifications', () {
      test('should notify listeners when current card changes', () {
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
        provider.setCurrentCard(card);

        // Assert
        expect(notificationReceived, isTrue);
      });

      test('should notify listeners when navigating', () {
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

        provider.setCurrentCard(card1);
        provider.setCurrentCard(card2);

        bool notificationReceived = false;
        provider.addListener(() {
          notificationReceived = true;
        });

        // Act
        provider.goToPreviousCard();

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

      test('should notify listeners when history is cleared', () {
        // Arrange
        final card = MTGCard(
          id: 'test-card-1',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        provider.setCurrentCard(card);

        bool notificationReceived = false;
        provider.addListener(() {
          notificationReceived = true;
        });

        // Act
        provider.clearHistory();

        // Assert
        expect(notificationReceived, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle empty history navigation', () {
        // Assert
        expect(provider.canGoToPrevious, isFalse);
        expect(provider.canGoToNext, isFalse);

        // Act & Assert
        expect(() => provider.goToPreviousCard(), returnsNormally);
        expect(() => provider.goToNextCard(), returnsNormally);
      });

      test('should handle duplicate cards in history', () {
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
        provider.setCurrentCard(card);
        provider.setCurrentCard(card);

        // Assert
        expect(provider.cardHistory.length, equals(2));
        expect(provider.cardHistory[0], equals(card));
        expect(provider.cardHistory[1], equals(card));
      });

      test('should handle rapid navigation changes', () {
        // Arrange
        final cards = List.generate(
            5,
            (i) => MTGCard(
                  id: 'test-card-$i',
                  name: 'Test Card $i',
                  typeLine: 'Instant',
                  set: 'test',
                  setName: 'Test Set',
                  rarity: 'common',
                ));

        for (final card in cards) {
          provider.setCurrentCard(card);
        }

        // Act
        provider.goToPreviousCard();
        provider.goToPreviousCard();
        provider.goToNextCard();
        provider.goToPreviousCard();
        provider.goToNextCard();
        provider.goToNextCard();

        // Assert
        expect(provider.currentCard, equals(cards[4]));
        expect(provider.currentIndex, equals(4));
      });

      test('should handle multiple rapid state changes', () {
        // Act
        provider.setLoading(true);
        provider.setLoading(false);
        provider.setError('Error 1');
        provider.setError('Error 2');
        provider.clearError();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
      });
    });
  });
}

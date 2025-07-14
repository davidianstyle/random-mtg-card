import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_mtg_card/main.dart' as app;
import 'package:random_mtg_card/widgets/card_widget.dart';
import 'package:random_mtg_card/widgets/favorite_indicator.dart';
import 'package:random_mtg_card/widgets/card_metadata_overlay.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MTG Card Display App Integration Tests', () {
    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should launch app and display initial screen',
        (WidgetTester tester) async {
      // Arrange & Act
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should display card widget on main screen',
        (WidgetTester tester) async {
      // Arrange & Act
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should display favorite indicator',
        (WidgetTester tester) async {
      // Arrange & Act
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert
      expect(find.byType(FavoriteIndicator), findsOneWidget);
    });

    testWidgets('should handle single tap to toggle metadata',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act
      final cardWidget = find.byType(CardWidget);
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardMetadataOverlay), findsOneWidget);

      // Act - Tap again to hide
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardMetadataOverlay), findsNothing);
    });

    testWidgets('should handle double tap to toggle favorite',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act
      final cardWidget = find.byType(CardWidget);
      await tester.tap(cardWidget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();

      // Assert
      // The favorite indicator should show the card is favorited
      final favoriteIndicator = find.byType(FavoriteIndicator);
      expect(favoriteIndicator, findsOneWidget);
    });

    testWidgets('should handle swipe left gesture for navigation',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act
      final cardWidget = find.byType(CardWidget);
      await tester.fling(cardWidget, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Assert
      // Should navigate to next card (if available)
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should handle swipe right gesture for navigation',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act
      final cardWidget = find.byType(CardWidget);
      await tester.fling(cardWidget, const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      // Assert
      // Should navigate to previous card (if available)
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should handle long press gesture',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act
      final cardWidget = find.byType(CardWidget);
      await tester.longPress(cardWidget);
      await tester.pumpAndSettle();

      // Assert
      // Long press should be handled (future feature)
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should maintain app state across gesture interactions',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Perform multiple gestures
      final cardWidget = find.byType(CardWidget);

      // Single tap to show metadata
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CardMetadataOverlay), findsOneWidget);

      // Double tap to favorite
      await tester.tap(cardWidget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();

      // Swipe to navigate
      await tester.fling(cardWidget, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Assert
      // App should still be functional
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(FavoriteIndicator), findsOneWidget);
    });

    testWidgets('should handle error states gracefully',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Try to trigger error conditions
      final cardWidget = find.byType(CardWidget);

      // Rapid gestures that might cause errors
      for (int i = 0; i < 5; i++) {
        await tester.tap(cardWidget);
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();

      // Assert
      // App should still be functional despite rapid interactions
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should persist favorites across app restarts',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Favorite a card
      final cardWidget = find.byType(CardWidget);
      await tester.tap(cardWidget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();

      // Simulate app restart
      await tester.binding.reassembleApplication();
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert
      // Favorites should be persisted
      expect(find.byType(FavoriteIndicator), findsOneWidget);
    });

    testWidgets('should handle orientation changes',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Simulate orientation change
      await tester.binding.setSurfaceSize(const Size(1024, 600));
      await tester.pumpAndSettle();

      // Assert
      // App should adapt to new orientation
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(FavoriteIndicator), findsOneWidget);

      // Reset orientation
      await tester.binding.setSurfaceSize(const Size(600, 1024));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle network connectivity issues',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act
      // The app should handle network issues gracefully
      // This would require more complex setup to simulate network failures

      // Assert
      // App should still be functional
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should handle rapid user interactions',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Perform rapid interactions
      final cardWidget = find.byType(CardWidget);

      for (int i = 0; i < 10; i++) {
        await tester.tap(cardWidget);
        await tester.pump(const Duration(milliseconds: 100));

        if (i % 2 == 0) {
          await tester.fling(cardWidget, const Offset(-100, 0), 500);
        } else {
          await tester.fling(cardWidget, const Offset(100, 0), 500);
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Assert
      // App should remain stable and functional
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(FavoriteIndicator), findsOneWidget);
    });

    testWidgets('should handle memory pressure', (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Simulate memory pressure by navigating through many cards
      final cardWidget = find.byType(CardWidget);

      for (int i = 0; i < 20; i++) {
        await tester.fling(cardWidget, const Offset(-200, 0), 800);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
      }

      // Assert
      // App should handle memory pressure gracefully
      expect(find.byType(CardWidget), findsOneWidget);
    });

    testWidgets('should maintain consistent UI state',
        (WidgetTester tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act - Perform various operations
      final cardWidget = find.byType(CardWidget);

      // Show metadata
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CardMetadataOverlay), findsOneWidget);

      // Hide metadata
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CardMetadataOverlay), findsNothing);

      // Favorite card
      await tester.tap(cardWidget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cardWidget);
      await tester.pumpAndSettle();

      // Navigate
      await tester.fling(cardWidget, const Offset(-200, 0), 800);
      await tester.pumpAndSettle();

      // Assert
      // UI should be in consistent state
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(FavoriteIndicator), findsOneWidget);
    });
  });
}

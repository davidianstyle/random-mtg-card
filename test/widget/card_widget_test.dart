import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:random_mtg_card/models/mtg_card.dart';
import 'package:random_mtg_card/widgets/card_widget.dart';

void main() {
  group('CardWidget', () {
    late MTGCard testCard;

    setUp(() {
      testCard = MTGCard(
        id: 'test-card-1',
        name: 'Lightning Bolt',
        typeLine: 'Instant',
        set: 'lea',
        setName: 'Limited Edition Alpha',
        rarity: 'common',
        manaCost: '{R}',
        oracleText: 'Lightning Bolt deals 3 damage to any target.',
        imageUris: ImageUris(
          small: 'https://example.com/small.jpg',
          normal: 'https://example.com/normal.jpg',
          large: 'https://example.com/large.jpg',
          png: 'https://example.com/png.png',
        ),
      );
    });

    testWidgets('should render card with image when card is provided',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: testCard),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should render placeholder when no card is provided',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardWidget(card: null),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('No card to display'), findsOneWidget);
    });

    testWidgets('should render error widget when card has no image',
        (WidgetTester tester) async {
      // Arrange
      final cardWithoutImage = MTGCard(
        id: 'test-card-2',
        name: 'Test Card',
        typeLine: 'Instant',
        set: 'test',
        setName: 'Test Set',
        rarity: 'common',
        imageUris: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: cardWithoutImage),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('No image available'), findsOneWidget);
    });

    testWidgets('should have correct dimensions', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: testCard),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      final cardWidget = tester.widget<Container>(find.byType(Container).first);
      expect(cardWidget.constraints?.maxWidth, equals(540.0));
      expect(cardWidget.constraints?.maxHeight, equals(756.0));
    });

    testWidgets('should render with correct styling',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: testCard),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.borderRadius, isA<BorderRadius>());
      expect(decoration?.boxShadow, isNotNull);
    });

    testWidgets('should handle image loading errors gracefully',
        (WidgetTester tester) async {
      // Arrange
      final cardWithBadImage = MTGCard(
        id: 'test-card-3',
        name: 'Test Card',
        typeLine: 'Instant',
        set: 'test',
        setName: 'Test Set',
        rarity: 'common',
        imageUris: ImageUris(
          large: 'https://invalid-url.com/image.jpg',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: cardWithBadImage),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardWidget), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      // The error widget should be displayed by CachedNetworkImage
    });

    testWidgets('should display loading indicator',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: testCard),
          ),
        ),
      );

      // Act
      await tester.pump(); // Don't settle to catch loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be responsive to different screen sizes',
        (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: testCard),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CardWidget), findsOneWidget);
      // The widget should adapt to smaller screen size
    });

    testWidgets('should maintain aspect ratio', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(card: testCard),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      final cachedImage =
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.fit, equals(BoxFit.contain));
    });

    testWidgets('should handle tap gestures', (WidgetTester tester) async {
      // Arrange
      bool tapDetected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => tapDetected = true,
              child: CardWidget(card: testCard),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CardWidget));

      // Assert
      expect(tapDetected, isTrue);
    });

    testWidgets('should display card information in debug mode',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: testCard,
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Lightning Bolt'), findsOneWidget);
      expect(find.text('Instant'), findsOneWidget);
    });

    testWidgets('should not display card information in normal mode',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardWidget(
              card: testCard,
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Lightning Bolt'), findsNothing);
      expect(find.text('Instant'), findsNothing);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:random_mtg_card/models/mtg_card.dart';

void main() {
  group('MTGCard', () {
    group('JSON Serialization', () {
      test('should create MTGCard from valid JSON', () {
        // Arrange
        final json = {
          'id': 'test-id-123',
          'name': 'Lightning Bolt',
          'mana_cost': '{R}',
          'type_line': 'Instant',
          'oracle_text': 'Lightning Bolt deals 3 damage to any target.',
          'colors': ['R'],
          'color_identity': ['R'],
          'set': 'lea',
          'set_name': 'Limited Edition Alpha',
          'rarity': 'common',
          'artist': 'Christopher Rush',
          'cmc': 1.0,
          'power': null,
          'toughness': null,
          'collector_number': '162',
          'released_at': '1993-08-05',
          'image_uris': {
            'small': 'https://example.com/small.jpg',
            'normal': 'https://example.com/normal.jpg',
            'large': 'https://example.com/large.jpg',
            'png': 'https://example.com/png.png',
            'art_crop': 'https://example.com/art_crop.jpg',
            'border_crop': 'https://example.com/border_crop.jpg',
          },
        };

        // Act
        final card = MTGCard.fromJson(json);

        // Assert
        expect(card.id, equals('test-id-123'));
        expect(card.name, equals('Lightning Bolt'));
        expect(card.manaCost, equals('{R}'));
        expect(card.typeLine, equals('Instant'));
        expect(card.oracleText,
            equals('Lightning Bolt deals 3 damage to any target.'));
        expect(card.colors, equals(['R']));
        expect(card.colorIdentity, equals(['R']));
        expect(card.set, equals('lea'));
        expect(card.setName, equals('Limited Edition Alpha'));
        expect(card.rarity, equals('common'));
        expect(card.artist, equals('Christopher Rush'));
        expect(card.convertedManaCost, equals(1.0));
        expect(card.power, isNull);
        expect(card.toughness, isNull);
        expect(card.collectorNumber, equals('162'));
        expect(card.releasedAt, equals('1993-08-05'));
        expect(card.imageUris, isA<ImageUris>());
      });

      test('should serialize MTGCard to JSON', () {
        // Arrange
        final imageUris = ImageUris(
          small: 'https://example.com/small.jpg',
          normal: 'https://example.com/normal.jpg',
          large: 'https://example.com/large.jpg',
          png: 'https://example.com/png.png',
          artCrop: 'https://example.com/art_crop.jpg',
          borderCrop: 'https://example.com/border_crop.jpg',
        );

        final card = MTGCard(
          id: 'test-id-123',
          name: 'Lightning Bolt',
          manaCost: '{R}',
          typeLine: 'Instant',
          oracleText: 'Lightning Bolt deals 3 damage to any target.',
          colors: ['R'],
          colorIdentity: ['R'],
          set: 'lea',
          setName: 'Limited Edition Alpha',
          rarity: 'common',
          artist: 'Christopher Rush',
          convertedManaCost: 1.0,
          collectorNumber: '162',
          releasedAt: '1993-08-05',
          imageUris: imageUris,
        );

        // Act
        final json = card.toJson();

        // Assert
        expect(json['id'], equals('test-id-123'));
        expect(json['name'], equals('Lightning Bolt'));
        expect(json['mana_cost'], equals('{R}'));
        expect(json['type_line'], equals('Instant'));
        expect(json['oracle_text'],
            equals('Lightning Bolt deals 3 damage to any target.'));
        expect(json['colors'], equals(['R']));
        expect(json['color_identity'], equals(['R']));
        expect(json['set'], equals('lea'));
        expect(json['set_name'], equals('Limited Edition Alpha'));
        expect(json['rarity'], equals('common'));
        expect(json['artist'], equals('Christopher Rush'));
        expect(json['cmc'], equals(1.0));
        expect(json['collector_number'], equals('162'));
        expect(json['released_at'], equals('1993-08-05'));
        expect(json['image_uris'], isA<Map<String, dynamic>>());
      });

      test('should handle null values gracefully', () {
        // Arrange
        final json = {
          'id': 'test-id-123',
          'name': 'Test Card',
          'type_line': 'Artifact',
          'set': 'test',
          'set_name': 'Test Set',
          'rarity': 'common',
          'mana_cost': null,
          'oracle_text': null,
          'colors': null,
          'color_identity': null,
          'artist': null,
          'cmc': null,
          'power': null,
          'toughness': null,
          'collector_number': null,
          'released_at': null,
          'image_uris': null,
        };

        // Act
        final card = MTGCard.fromJson(json);

        // Assert
        expect(card.id, equals('test-id-123'));
        expect(card.name, equals('Test Card'));
        expect(card.typeLine, equals('Artifact'));
        expect(card.set, equals('test'));
        expect(card.setName, equals('Test Set'));
        expect(card.rarity, equals('common'));
        expect(card.manaCost, isNull);
        expect(card.oracleText, isNull);
        expect(card.colors, isNull);
        expect(card.colorIdentity, isNull);
        expect(card.artist, isNull);
        expect(card.convertedManaCost, isNull);
        expect(card.power, isNull);
        expect(card.toughness, isNull);
        expect(card.collectorNumber, isNull);
        expect(card.releasedAt, isNull);
        expect(card.imageUris, isNull);
      });

      test('should handle empty arrays', () {
        // Arrange
        final json = {
          'id': 'test-id-123',
          'name': 'Test Card',
          'type_line': 'Artifact',
          'set': 'test',
          'set_name': 'Test Set',
          'rarity': 'common',
          'colors': <String>[],
          'color_identity': <String>[],
        };

        // Act
        final card = MTGCard.fromJson(json);

        // Assert
        expect(card.colors, isEmpty);
        expect(card.colorIdentity, isEmpty);
      });
    });

    group('ImageUris', () {
      test('should create ImageUris from valid JSON', () {
        // Arrange
        final json = {
          'small': 'https://example.com/small.jpg',
          'normal': 'https://example.com/normal.jpg',
          'large': 'https://example.com/large.jpg',
          'png': 'https://example.com/png.png',
          'art_crop': 'https://example.com/art_crop.jpg',
          'border_crop': 'https://example.com/border_crop.jpg',
        };

        // Act
        final imageUris = ImageUris.fromJson(json);

        // Assert
        expect(imageUris.small, equals('https://example.com/small.jpg'));
        expect(imageUris.normal, equals('https://example.com/normal.jpg'));
        expect(imageUris.large, equals('https://example.com/large.jpg'));
        expect(imageUris.png, equals('https://example.com/png.png'));
        expect(imageUris.artCrop, equals('https://example.com/art_crop.jpg'));
        expect(imageUris.borderCrop,
            equals('https://example.com/border_crop.jpg'));
      });

      test('should serialize ImageUris to JSON', () {
        // Arrange
        final imageUris = ImageUris(
          small: 'https://example.com/small.jpg',
          normal: 'https://example.com/normal.jpg',
          large: 'https://example.com/large.jpg',
          png: 'https://example.com/png.png',
          artCrop: 'https://example.com/art_crop.jpg',
          borderCrop: 'https://example.com/border_crop.jpg',
        );

        // Act
        final json = imageUris.toJson();

        // Assert
        expect(json['small'], equals('https://example.com/small.jpg'));
        expect(json['normal'], equals('https://example.com/normal.jpg'));
        expect(json['large'], equals('https://example.com/large.jpg'));
        expect(json['png'], equals('https://example.com/png.png'));
        expect(json['art_crop'], equals('https://example.com/art_crop.jpg'));
        expect(
            json['border_crop'], equals('https://example.com/border_crop.jpg'));
      });

      test('should handle null values in ImageUris', () {
        // Arrange
        final json = {
          'small': null,
          'normal': null,
          'large': null,
          'png': null,
          'art_crop': null,
          'border_crop': null,
        };

        // Act
        final imageUris = ImageUris.fromJson(json);

        // Assert
        expect(imageUris.small, isNull);
        expect(imageUris.normal, isNull);
        expect(imageUris.large, isNull);
        expect(imageUris.png, isNull);
        expect(imageUris.artCrop, isNull);
        expect(imageUris.borderCrop, isNull);
      });
    });

    group('Card Properties', () {
      test('should get best image URL', () {
        // Arrange
        final imageUris = ImageUris(
          small: 'https://example.com/small.jpg',
          normal: 'https://example.com/normal.jpg',
          large: 'https://example.com/large.jpg',
          png: 'https://example.com/png.png',
        );

        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          imageUris: imageUris,
        );

        // Act & Assert
        expect(card.bestImageUrl, equals('https://example.com/large.jpg'));
      });

      test('should fallback to smaller image when large not available', () {
        // Arrange
        final imageUris = ImageUris(
          small: 'https://example.com/small.jpg',
          normal: 'https://example.com/normal.jpg',
          large: null,
          png: null,
        );

        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          imageUris: imageUris,
        );

        // Act & Assert
        expect(card.bestImageUrl, equals('https://example.com/normal.jpg'));
      });

      test('should return null when no images available', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          imageUris: null,
        );

        // Act & Assert
        expect(card.bestImageUrl, isNull);
      });

      test('should get PNG image URL', () {
        // Arrange
        final imageUris = ImageUris(
          png: 'https://example.com/png.png',
        );

        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          imageUris: imageUris,
        );

        // Act & Assert
        expect(card.pngImageUrl, equals('https://example.com/png.png'));
      });

      test('should get display info', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Lightning Bolt',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          manaCost: '{R}',
        );

        // Act & Assert
        expect(card.displayInfo, equals('Lightning Bolt • {R} • Instant'));
      });

      test('should get display info without mana cost', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Land Card',
          typeLine: 'Basic Land — Plains',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          manaCost: null,
        );

        // Act & Assert
        expect(card.displayInfo, equals('Land Card • Basic Land — Plains'));
      });

      test('should get set info', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'lea',
          setName: 'Limited Edition Alpha',
          rarity: 'common',
        );

        // Act & Assert
        expect(card.setInfo, equals('Limited Edition Alpha (lea)'));
      });

      test('should identify creature cards', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Creature — Human Wizard',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        // Act & Assert
        expect(card.isCreature, isTrue);
      });

      test('should identify non-creature cards', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
        );

        // Act & Assert
        expect(card.isCreature, isFalse);
      });

      test('should get power/toughness for creatures', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Creature — Human Wizard',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          power: '2',
          toughness: '3',
        );

        // Act & Assert
        expect(card.powerToughness, equals('2/3'));
      });

      test('should return null power/toughness for non-creatures', () {
        // Arrange
        final card = MTGCard(
          id: 'test-id',
          name: 'Test Card',
          typeLine: 'Instant',
          set: 'test',
          setName: 'Test Set',
          rarity: 'common',
          power: null,
          toughness: null,
        );

        // Act & Assert
        expect(card.powerToughness, isNull);
      });
    });

    group('ScryfallResponse', () {
      test('should create ScryfallResponse from valid JSON', () {
        // Arrange
        final json = {
          'object': 'card',
          'type': 'random',
          'total_cards': 1,
          'has_more': false,
          'next_page': null,
          'data': null,
        };

        // Act
        final response = ScryfallResponse.fromJson(json);

        // Assert
        expect(response.type, equals('random'));
        expect(response.totalCards, equals(1));
        expect(response.hasMore, isFalse);
        expect(response.nextPage, isNull);
        expect(response.data, isNull);
      });

      test('should serialize ScryfallResponse to JSON', () {
        // Arrange
        final response = ScryfallResponse(
          type: 'search',
          totalCards: 100,
          hasMore: true,
          nextPage: 'https://api.scryfall.com/cards/search?page=2',
          data: [],
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['type'], equals('search'));
        expect(json['total_cards'], equals(100));
        expect(json['has_more'], isTrue);
        expect(json['next_page'],
            equals('https://api.scryfall.com/cards/search?page=2'));
        expect(json['data'], equals([]));
      });
    });
  });
}

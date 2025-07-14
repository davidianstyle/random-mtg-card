import 'package:json_annotation/json_annotation.dart';

part 'mtg_card.g.dart';

@JsonSerializable()
class MTGCard {
  final String id;
  final String name;

  @JsonKey(name: 'mana_cost')
  final String? manaCost;

  @JsonKey(name: 'type_line')
  final String typeLine;

  @JsonKey(name: 'oracle_text')
  final String? oracleText;

  @JsonKey(name: 'image_uris')
  final ImageUris? imageUris;

  final String set;

  @JsonKey(name: 'set_name')
  final String setName;

  final String rarity;

  final List<String>? colors;

  @JsonKey(name: 'color_identity')
  final List<String>? colorIdentity;

  @JsonKey(name: 'cmc')
  final double? convertedManaCost;

  final String? power;
  final String? toughness;

  @JsonKey(name: 'artist')
  final String? artist;

  @JsonKey(name: 'collector_number')
  final String? collectorNumber;

  @JsonKey(name: 'released_at')
  final String? releasedAt;

  MTGCard({
    required this.id,
    required this.name,
    this.manaCost,
    required this.typeLine,
    this.oracleText,
    this.imageUris,
    required this.set,
    required this.setName,
    required this.rarity,
    this.colors,
    this.colorIdentity,
    this.convertedManaCost,
    this.power,
    this.toughness,
    this.artist,
    this.collectorNumber,
    this.releasedAt,
  });

  factory MTGCard.fromJson(Map<String, dynamic> json) =>
      _$MTGCardFromJson(json);
  Map<String, dynamic> toJson() => _$MTGCardToJson(this);

  /// Returns the best available image URL for display
  String? get bestImageUrl {
    if (imageUris == null) return null;

    // Prefer large, then normal, then small
    return imageUris!.large ?? imageUris!.normal ?? imageUris!.small;
  }

  /// Returns the PNG image URL if available (highest quality)
  String? get pngImageUrl {
    return imageUris?.png;
  }

  /// Returns a formatted string for display
  String get displayInfo {
    final parts = <String>[
      name,
      if (manaCost != null && manaCost!.isNotEmpty) manaCost!,
      typeLine,
    ];
    return parts.join(' • ');
  }

  /// Returns set information for display
  String get setInfo {
    return '$setName ($set)';
  }

  /// Checks if this card is a creature
  bool get isCreature {
    return typeLine.toLowerCase().contains('creature');
  }

  /// Returns power/toughness for creatures
  String? get powerToughness {
    if (power != null && toughness != null) {
      return '$power/$toughness';
    }
    return null;
  }
}

@JsonSerializable()
class ImageUris {
  final String? small;
  final String? normal;
  final String? large;
  final String? png;

  @JsonKey(name: 'art_crop')
  final String? artCrop;

  @JsonKey(name: 'border_crop')
  final String? borderCrop;

  ImageUris({
    this.small,
    this.normal,
    this.large,
    this.png,
    this.artCrop,
    this.borderCrop,
  });

  factory ImageUris.fromJson(Map<String, dynamic> json) =>
      _$ImageUrisFromJson(json);
  Map<String, dynamic> toJson() => _$ImageUrisToJson(this);
}

@JsonSerializable()
class ScryfallResponse {
  final String? object;
  final String? type;
  @JsonKey(name: 'total_cards')
  final int? totalCards;
  final List<MTGCard>? data;

  @JsonKey(name: 'has_more')
  final bool? hasMore;

  @JsonKey(name: 'next_page')
  final String? nextPage;

  ScryfallResponse({
    this.object,
    this.type,
    this.totalCards,
    this.data,
    this.hasMore,
    this.nextPage,
  });

  factory ScryfallResponse.fromJson(Map<String, dynamic> json) =>
      _$ScryfallResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ScryfallResponseToJson(this);
}

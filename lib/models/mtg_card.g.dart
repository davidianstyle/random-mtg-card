// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mtg_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MTGCard _$MTGCardFromJson(Map<String, dynamic> json) => MTGCard(
      id: json['id'] as String,
      name: json['name'] as String,
      manaCost: json['mana_cost'] as String?,
      typeLine: json['type_line'] as String,
      oracleText: json['oracle_text'] as String?,
      imageUris: json['image_uris'] == null
          ? null
          : ImageUris.fromJson(json['image_uris'] as Map<String, dynamic>),
      set: json['set'] as String,
      setName: json['set_name'] as String,
      rarity: json['rarity'] as String,
      colors:
          (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList(),
      colorIdentity: (json['color_identity'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      convertedManaCost: (json['cmc'] as num?)?.toDouble(),
      power: json['power'] as String?,
      toughness: json['toughness'] as String?,
      artist: json['artist'] as String?,
      collectorNumber: json['collector_number'] as String?,
      releasedAt: json['released_at'] as String?,
    );

Map<String, dynamic> _$MTGCardToJson(MTGCard instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      if (instance.manaCost case final value?) 'mana_cost': value,
      'type_line': instance.typeLine,
      if (instance.oracleText case final value?) 'oracle_text': value,
      if (instance.imageUris?.toJson() case final value?) 'image_uris': value,
      'set': instance.set,
      'set_name': instance.setName,
      'rarity': instance.rarity,
      if (instance.colors case final value?) 'colors': value,
      if (instance.colorIdentity case final value?) 'color_identity': value,
      if (instance.convertedManaCost case final value?) 'cmc': value,
      if (instance.power case final value?) 'power': value,
      if (instance.toughness case final value?) 'toughness': value,
      if (instance.artist case final value?) 'artist': value,
      if (instance.collectorNumber case final value?) 'collector_number': value,
      if (instance.releasedAt case final value?) 'released_at': value,
    };

ImageUris _$ImageUrisFromJson(Map<String, dynamic> json) => ImageUris(
      small: json['small'] as String?,
      normal: json['normal'] as String?,
      large: json['large'] as String?,
      png: json['png'] as String?,
      artCrop: json['art_crop'] as String?,
      borderCrop: json['border_crop'] as String?,
    );

Map<String, dynamic> _$ImageUrisToJson(ImageUris instance) => <String, dynamic>{
      if (instance.small case final value?) 'small': value,
      if (instance.normal case final value?) 'normal': value,
      if (instance.large case final value?) 'large': value,
      if (instance.png case final value?) 'png': value,
      if (instance.artCrop case final value?) 'art_crop': value,
      if (instance.borderCrop case final value?) 'border_crop': value,
    };

ScryfallResponse _$ScryfallResponseFromJson(Map<String, dynamic> json) =>
    ScryfallResponse(
      object: json['object'] == null
          ? null
          : MTGCard.fromJson(json['object'] as Map<String, dynamic>),
      type: json['type'] as String?,
      totalCards: (json['totalCards'] as num?)?.toInt(),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => MTGCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['has_more'] as bool?,
      nextPage: json['next_page'] as String?,
    );

Map<String, dynamic> _$ScryfallResponseToJson(ScryfallResponse instance) =>
    <String, dynamic>{
      if (instance.object?.toJson() case final value?) 'object': value,
      if (instance.type case final value?) 'type': value,
      if (instance.totalCards case final value?) 'totalCards': value,
      if (instance.data?.map((e) => e.toJson()).toList() case final value?)
        'data': value,
      if (instance.hasMore case final value?) 'has_more': value,
      if (instance.nextPage case final value?) 'next_page': value,
    };

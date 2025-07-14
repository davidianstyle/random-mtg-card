import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/mtg_card.dart';
import 'config_service.dart';

// Filter option models
class FilterOption {
  final String value;
  final String label;
  final String? description;
  
  FilterOption({required this.value, required this.label, this.description});
}

class ScryfallService {
  static ScryfallService? _instance;
  static ScryfallService get instance => _instance ??= ScryfallService._();
  
  ScryfallService._();
  
  final ConfigService _config = ConfigService.instance;
  
  // Rate limiting - Scryfall asks for 50-100ms between requests
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);
  DateTime _lastRequestTime = DateTime.now();
  
  // Cache for filter options to avoid repeated API calls
  Map<String, List<FilterOption>> _filterCache = {};
  
  /// Get a random MTG card
  Future<MTGCard?> getRandomCard() async {
    try {
      await _waitForRateLimit();
      
      final url = '${_config.apiBaseUrl}/cards/random';
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MTGCard.fromJson(json);
      } else {
        print('Error fetching random card: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception fetching random card: $e');
      return null;
    }
  }
  
  /// Search for cards with optional filters
  Future<List<MTGCard>> searchCards({
    String? query,
    List<String>? sets,
    List<String>? colors,
    List<String>? types,
    List<String>? rarity,
    String? format,
    int page = 1,
  }) async {
    try {
      await _waitForRateLimit();
      
      final queryParts = <String>[];
      
      if (query != null && query.isNotEmpty) {
        queryParts.add(query);
      }
      
      if (sets != null && sets.isNotEmpty) {
        queryParts.add('(${sets.map((s) => 'set:$s').join(' OR ')})');
      }
      
      if (colors != null && colors.isNotEmpty) {
        queryParts.add('(${colors.map((c) => 'color:$c').join(' OR ')})');
      }
      
      if (types != null && types.isNotEmpty) {
        queryParts.add('(${types.map((t) => 'type:$t').join(' OR ')})');
      }
      
      if (rarity != null && rarity.isNotEmpty) {
        queryParts.add('(${rarity.map((r) => 'rarity:$r').join(' OR ')})');
      }
      
      if (format != null && format.isNotEmpty) {
        queryParts.add('format:$format');
      }
      
      final searchQuery = queryParts.join(' ');
      final url = '${_config.apiBaseUrl}/cards/search?q=${Uri.encodeComponent(searchQuery)}&page=$page';
      
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List;
        return data.map((cardJson) => MTGCard.fromJson(cardJson)).toList();
      } else {
        print('Error searching cards: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception searching cards: $e');
      return [];
    }
  }
  
  /// Get a specific card by ID
  Future<MTGCard?> getCard(String id) async {
    try {
      await _waitForRateLimit();
      
      final url = '${_config.apiBaseUrl}/cards/$id';
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return MTGCard.fromJson(json);
      } else {
        print('Error fetching card $id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception fetching card $id: $e');
      return null;
    }
  }
  
  /// Get all available sets
  Future<List<Map<String, dynamic>>> getSets() async {
    try {
      await _waitForRateLimit();
      
      final url = '${_config.apiBaseUrl}/sets';
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(json['data']);
      } else {
        print('Error fetching sets: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching sets: $e');
      return [];
    }
  }
  
  /// Get a random card with applied filters
  Future<MTGCard?> getRandomCardWithFilters() async {
    if (!_config.filtersEnabled) {
      return getRandomCard();
    }
    
    try {
      final searchResults = await searchCards(
        sets: _config.filterSets.isNotEmpty ? _config.filterSets : null,
        colors: _config.filterColors.isNotEmpty ? _config.filterColors : null,
        types: _config.filterCardTypes.isNotEmpty ? _config.filterCardTypes : null,
        rarity: _config.filterRarity.isNotEmpty ? _config.filterRarity : null,
        format: _config.filterFormat.isNotEmpty ? _config.filterFormat : null,
      );
      
      if (searchResults.isNotEmpty) {
        // Return a random card from the filtered results
        searchResults.shuffle();
        return searchResults.first;
      } else {
        // Fallback to regular random card if no results
        return getRandomCard();
      }
    } catch (e) {
      print('Exception getting filtered random card: $e');
      // Fallback to regular random card
      return getRandomCard();
    }
  }
  
  /// Get available sets for filtering
  Future<List<FilterOption>> getAvailableSets() async {
    if (_filterCache.containsKey('sets')) {
      return _filterCache['sets']!;
    }
    
    try {
      await _waitForRateLimit();
      
      final url = '${_config.apiBaseUrl}/sets';
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final sets = json['data'] as List;
        
        final options = sets.map<FilterOption>((set) {
          return FilterOption(
            value: set['code'] as String,
            label: set['name'] as String,
            description: '${set['set_type']} • ${set['released_at']}',
          );
        }).toList();
        
        // Sort by release date (newest first)
        options.sort((a, b) => b.description!.compareTo(a.description!));
        
        _filterCache['sets'] = options;
        return options;
      } else {
        print('Error fetching sets: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching sets: $e');
      return [];
    }
  }
  
  /// Get available colors for filtering
  Future<List<FilterOption>> getAvailableColors() async {
    if (_filterCache.containsKey('colors')) {
      return _filterCache['colors']!;
    }
    
    final options = [
      FilterOption(value: 'W', label: 'White', description: 'Plains'),
      FilterOption(value: 'U', label: 'Blue', description: 'Island'),
      FilterOption(value: 'B', label: 'Black', description: 'Swamp'),
      FilterOption(value: 'R', label: 'Red', description: 'Mountain'),
      FilterOption(value: 'G', label: 'Green', description: 'Forest'),
      FilterOption(value: 'C', label: 'Colorless', description: 'Generic mana'),
    ];
    
    _filterCache['colors'] = options;
    return options;
  }
  
  /// Get available card types for filtering
  Future<List<FilterOption>> getAvailableCardTypes() async {
    if (_filterCache.containsKey('card_types')) {
      return _filterCache['card_types']!;
    }
    
    try {
      await _waitForRateLimit();
      
      final url = '${_config.apiBaseUrl}/catalog/card-types';
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final types = json['data'] as List<dynamic>;
        
        final options = types.map<FilterOption>((type) {
          return FilterOption(
            value: type.toString().toLowerCase(),
            label: type.toString(),
          );
        }).toList();
        
        // Sort alphabetically
        options.sort((a, b) => a.label.compareTo(b.label));
        
        _filterCache['card_types'] = options;
        return options;
      } else {
        print('Error fetching card types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching card types: $e');
      return [];
    }
  }
  
  /// Get available creature types for filtering
  Future<List<FilterOption>> getAvailableCreatureTypes() async {
    if (_filterCache.containsKey('creature_types')) {
      return _filterCache['creature_types']!;
    }
    
    try {
      await _waitForRateLimit();
      
      final url = '${_config.apiBaseUrl}/catalog/creature-types';
      final response = await _makeRequest(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final types = json['data'] as List<dynamic>;
        
        final options = types.map<FilterOption>((type) {
          return FilterOption(
            value: type.toString().toLowerCase(),
            label: type.toString(),
          );
        }).toList();
        
        // Sort alphabetically
        options.sort((a, b) => a.label.compareTo(b.label));
        
        _filterCache['creature_types'] = options;
        return options;
      } else {
        print('Error fetching creature types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching creature types: $e');
      return [];
    }
  }
  
  /// Get available rarities for filtering
  Future<List<FilterOption>> getAvailableRarities() async {
    if (_filterCache.containsKey('rarities')) {
      return _filterCache['rarities']!;
    }
    
    final options = [
      FilterOption(value: 'common', label: 'Common', description: 'Most frequent'),
      FilterOption(value: 'uncommon', label: 'Uncommon', description: 'Less frequent'),
      FilterOption(value: 'rare', label: 'Rare', description: 'Uncommon to find'),
      FilterOption(value: 'mythic', label: 'Mythic Rare', description: 'Very rare'),
      FilterOption(value: 'special', label: 'Special', description: 'Unique cards'),
      FilterOption(value: 'bonus', label: 'Bonus', description: 'Extra cards'),
    ];
    
    _filterCache['rarities'] = options;
    return options;
  }
  
  /// Get available formats for filtering
  Future<List<FilterOption>> getAvailableFormats() async {
    if (_filterCache.containsKey('formats')) {
      return _filterCache['formats']!;
    }
    
    final options = [
      FilterOption(value: 'standard', label: 'Standard', description: 'Current competitive format'),
      FilterOption(value: 'modern', label: 'Modern', description: 'Cards from 2003 onwards'),
      FilterOption(value: 'legacy', label: 'Legacy', description: 'All cards except banned'),
      FilterOption(value: 'vintage', label: 'Vintage', description: 'All cards with restrictions'),
      FilterOption(value: 'commander', label: 'Commander', description: '100-card singleton'),
      FilterOption(value: 'pioneer', label: 'Pioneer', description: 'Cards from Return to Ravnica onwards'),
      FilterOption(value: 'historic', label: 'Historic', description: 'Arena format'),
      FilterOption(value: 'pauper', label: 'Pauper', description: 'Commons only'),
      FilterOption(value: 'brawl', label: 'Brawl', description: 'Standard-legal Commander'),
      FilterOption(value: 'future', label: 'Future', description: 'Upcoming releases'),
    ];
    
    _filterCache['formats'] = options;
    return options;
  }
  
  /// Clear the filter cache (useful for refreshing data)
  void clearFilterCache() {
    _filterCache.clear();
  }
  
  /// Make HTTP request with retry logic
  Future<http.Response> _makeRequest(String url) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'MTGCardDisplay/1.0',
          },
        ).timeout(Duration(seconds: _config.apiTimeout));
        
        _lastRequestTime = DateTime.now();
        
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 429) {
          // Rate limited, wait longer
          await Future.delayed(const Duration(seconds: 1));
        } else {
          // Other error, don't retry
          return response;
        }
      } on SocketException {
        print('Network error, attempt ${attempts + 1}/$maxAttempts');
      } on HttpException {
        print('HTTP error, attempt ${attempts + 1}/$maxAttempts');
      } catch (e) {
        print('Request error: $e, attempt ${attempts + 1}/$maxAttempts');
      }
      
      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    
    throw Exception('Failed to make request after $maxAttempts attempts');
  }
  
  /// Wait for rate limit compliance
  Future<void> _waitForRateLimit() async {
    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime);
    if (timeSinceLastRequest < _rateLimitDelay) {
      await Future.delayed(_rateLimitDelay - timeSinceLastRequest);
    }
  }
  
  /// Check if the service is available
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('${_config.apiBaseUrl}/cards/random'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MTGCardDisplay/1.0',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 
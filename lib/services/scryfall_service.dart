import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/mtg_card.dart';
import 'config_service.dart';

class ScryfallService {
  static ScryfallService? _instance;
  static ScryfallService get instance => _instance ??= ScryfallService._();
  
  ScryfallService._();
  
  final ConfigService _config = ConfigService.instance;
  
  // Rate limiting - Scryfall asks for 50-100ms between requests
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);
  DateTime _lastRequestTime = DateTime.now();
  
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
        types: _config.filterTypes.isNotEmpty ? _config.filterTypes : null,
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
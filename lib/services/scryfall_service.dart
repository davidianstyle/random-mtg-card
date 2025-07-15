import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/mtg_card.dart';
import '../utils/result.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';
import 'cache_service.dart';
import 'config_service.dart';
import 'service_locator.dart';

// Filter option models
class FilterOption {
  final String value;
  final String label;
  final String? description;

  FilterOption({required this.value, required this.label, this.description});
}

// Enhanced Scryfall service with better error handling and caching
class ScryfallService extends Service
    with PerformanceMonitoring, LoggerExtension {
  static ScryfallService? _instance;
  static ScryfallService get instance => _instance ??= ScryfallService._();

  ScryfallService._();

  late final ConfigService _config;
  late final CacheService _cache;
  late final http.Client _httpClient;

  // Rate limiting
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);
  DateTime _lastRequestTime = DateTime.now();

  // Circuit breaker for API failures
  int _failureCount = 0;
  DateTime? _circuitBreakerOpenTime;
  static const int _maxFailures = 5;
  static const Duration _circuitBreakerTimeout = Duration(minutes: 5);

  // Cache for filter options to avoid repeated API calls
  final Map<String, List<FilterOption>> _filterCache = {};

  Future<void> initialize() async {
    _config = getService<ConfigService>();
    _cache = getService<CacheService>();
    _httpClient = http.Client();

    logInfo('Scryfall service initialized');
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  // Circuit breaker check
  bool get _isCircuitBreakerOpen {
    if (_circuitBreakerOpenTime == null) return false;
    if (DateTime.now().difference(_circuitBreakerOpenTime!) >
        _circuitBreakerTimeout) {
      _circuitBreakerOpenTime = null;
      _failureCount = 0;
      return false;
    }
    return true;
  }

  void _recordFailure() {
    _failureCount++;
    if (_failureCount >= _maxFailures) {
      _circuitBreakerOpenTime = DateTime.now();
      logWarning(
          'Circuit breaker opened due to $_failureCount consecutive failures');
    }
  }

  void _recordSuccess() {
    _failureCount = 0;
    _circuitBreakerOpenTime = null;
  }

  // Enhanced random card fetch with caching and error handling
  Future<Result<MTGCard>> getRandomCardResult() async {
    return timeAsync('getRandomCard', () async {
      if (_isCircuitBreakerOpen) {
        return const Failure(ApiError(
          message: 'Service temporarily unavailable',
          statusCode: 503,
        ));
      }

      try {
        // Check cache first
        final cacheResult = await _cache.getApiResponse('random_card');
        if (cacheResult.isSuccess) {
          logDebug('Random card served from cache');
          final json = jsonDecode(cacheResult.dataOrNull!);
          return Success(MTGCard.fromJson(json));
        }

        // Make API request
        final result = await _makeApiRequest('/cards/random');
        return result.fold(
          (response) async {
            final json = jsonDecode(response);
            final card = MTGCard.fromJson(json);

            // Cache the response
            await _cache.cacheApiResponse('random_card', response,
                ttl: const Duration(minutes: 5));

            logInfo('Random card fetched successfully',
                context: {'card_id': card.id});
            return Success(card);
          },
          (error) => Failure(error),
        );
      } catch (e, stackTrace) {
        logError('Failed to get random card', error: e, stackTrace: stackTrace);
        return Failure(UnknownError(
            message: 'Failed to get random card', originalError: e));
      }
    });
  }

  // Enhanced card search with pagination and filtering
  Future<Result<List<MTGCard>>> searchCardsResult({
    String? query,
    List<String>? sets,
    List<String>? colors,
    List<String>? types,
    List<String>? rarity,
    String? format,
    int page = 1,
    int pageSize = 20,
  }) async {
    return timeAsync('searchCards', () async {
      if (_isCircuitBreakerOpen) {
        return const Failure(ApiError(
          message: 'Service temporarily unavailable',
          statusCode: 503,
        ));
      }

      try {
        // Build search query
        final searchQuery = _buildSearchQuery(
          query: query,
          sets: sets,
          colors: colors,
          types: types,
          rarity: rarity,
          format: format,
        );

        final cacheKey = 'search_${searchQuery}_${page}_$pageSize';

        // Check cache
        final cacheResult = await _cache.getApiResponse(cacheKey);
        if (cacheResult.isSuccess) {
          logDebug('Search results served from cache');
          final json = jsonDecode(cacheResult.dataOrNull!);
          final data = json['data'] as List;
          return Success(
              data.map((cardJson) => MTGCard.fromJson(cardJson)).toList());
        }

        // Make API request
        final url =
            '/cards/search?q=${Uri.encodeComponent(searchQuery)}&page=$page';
        final result = await _makeApiRequest(url);

        return result.fold(
          (response) async {
            final json = jsonDecode(response);
            final data = json['data'] as List;
            final cards =
                data.map((cardJson) => MTGCard.fromJson(cardJson)).toList();

            // Cache the response
            await _cache.cacheApiResponse(cacheKey, response,
                ttl: const Duration(hours: 1));

            logInfo('Search completed successfully', context: {
              'query': searchQuery,
              'results': cards.length,
              'page': page,
            });

            return Success(cards);
          },
          (error) => Failure(error),
        );
      } catch (e, stackTrace) {
        logError('Failed to search cards', error: e, stackTrace: stackTrace);
        return Failure(
            UnknownError(message: 'Failed to search cards', originalError: e));
      }
    });
  }

  // Get specific card by ID
  Future<Result<MTGCard>> getCardResult(String id) async {
    return timeAsync('getCard', () async {
      if (_isCircuitBreakerOpen) {
        return const Failure(ApiError(
          message: 'Service temporarily unavailable',
          statusCode: 503,
        ));
      }

      try {
        final cacheKey = 'card_$id';

        // Check cache
        final cacheResult = await _cache.getApiResponse(cacheKey);
        if (cacheResult.isSuccess) {
          logDebug('Card served from cache', context: {'card_id': id});
          final json = jsonDecode(cacheResult.dataOrNull!);
          return Success(MTGCard.fromJson(json));
        }

        // Make API request
        final result = await _makeApiRequest('/cards/$id');

        return result.fold(
          (response) async {
            final json = jsonDecode(response);
            final card = MTGCard.fromJson(json);

            // Cache the response
            await _cache.cacheApiResponse(cacheKey, response,
                ttl: const Duration(days: 1));

            logInfo('Card fetched successfully', context: {'card_id': id});
            return Success(card);
          },
          (error) => Failure(error),
        );
      } catch (e, stackTrace) {
        logError('Failed to get card',
            error: e, stackTrace: stackTrace, context: {'card_id': id});
        return Failure(
            UnknownError(message: 'Failed to get card', originalError: e));
      }
    });
  }

  // Download and cache card image
  Future<Result<Uint8List>> getCardImage(String imageUrl) async {
    return timeAsync('getCardImage', () async {
      try {
        // Check cache first
        final cacheResult = await _cache.getImage(imageUrl);
        if (cacheResult.isSuccess) {
          logDebug('Image served from cache');
          return cacheResult;
        }

        // Download image
        final response = await _httpClient.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final imageData = response.bodyBytes;

          // Cache the image
          await _cache.cacheImage(imageUrl, imageData);

          logInfo('Image downloaded and cached', context: {
            'url': imageUrl,
            'size_kb': imageData.length / 1024,
          });

          return Success(imageData);
        } else {
          return Failure(NetworkError(
            message: 'Failed to download image',
            code: response.statusCode,
          ));
        }
      } catch (e, stackTrace) {
        logError('Failed to get card image', error: e, stackTrace: stackTrace);
        return Failure(UnknownError(
            message: 'Failed to get card image', originalError: e));
      }
    });
  }

  // Check service availability
  Future<Result<bool>> checkServiceAvailability() async {
    return timeAsync('checkServiceAvailability', () async {
      try {
        final result = await _makeApiRequest('/cards/random');
        return result.fold(
          (_) => const Success(true),
          (error) => Failure(error),
        );
      } catch (e) {
        return Failure(
            UnknownError(message: 'Service check failed', originalError: e));
      }
    });
  }

  // LEGACY METHODS FOR BACKWARD COMPATIBILITY

  /// Get a random MTG card (legacy method)
  Future<MTGCard?> getRandomCard() async {
    final result = await getRandomCardResult();
    return result.dataOrNull;
  }

  /// Search for cards with optional filters (legacy method)
  Future<List<MTGCard>> searchCards({
    String? query,
    List<String>? sets,
    List<String>? colors,
    List<String>? types,
    List<String>? rarity,
    String? format,
    int page = 1,
  }) async {
    final result = await searchCardsResult(
      query: query,
      sets: sets,
      colors: colors,
      types: types,
      rarity: rarity,
      format: format,
      page: page,
    );
    return result.dataOrNull ?? [];
  }

  /// Get a specific card by ID (legacy method)
  Future<MTGCard?> getCard(String id) async {
    final result = await getCardResult(id);
    return result.dataOrNull;
  }

  /// Get all available sets (legacy method)
  Future<List<Map<String, dynamic>>> getSets() async {
    try {
      await _waitForRateLimit();

      final url = '${_config.apiBaseUrl}/sets';
      final response = await _makeRequest(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(json['data']);
      } else {
        debugPrint('Error fetching sets: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching sets: $e');
      return [];
    }
  }

  /// Get a random card with applied filters (legacy method)
  Future<MTGCard?> getRandomCardWithFilters() async {
    if (!_config.filtersEnabled) {
      return getRandomCard();
    }

    try {
      final searchResults = await searchCards(
        sets: _config.filterSets.isNotEmpty ? _config.filterSets : null,
        colors: _config.filterColors.isNotEmpty ? _config.filterColors : null,
        types:
            _config.filterCardTypes.isNotEmpty ? _config.filterCardTypes : null,
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
      debugPrint('Exception getting filtered random card: $e');
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
        debugPrint('Error fetching sets: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching sets: $e');
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
        debugPrint('Error fetching card types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching card types: $e');
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
        debugPrint('Error fetching creature types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching creature types: $e');
      return [];
    }
  }

  /// Get available rarities for filtering
  Future<List<FilterOption>> getAvailableRarities() async {
    if (_filterCache.containsKey('rarities')) {
      return _filterCache['rarities']!;
    }

    final options = [
      FilterOption(
          value: 'common', label: 'Common', description: 'Most frequent'),
      FilterOption(
          value: 'uncommon', label: 'Uncommon', description: 'Less frequent'),
      FilterOption(
          value: 'rare', label: 'Rare', description: 'Uncommon to find'),
      FilterOption(
          value: 'mythic', label: 'Mythic Rare', description: 'Very rare'),
      FilterOption(
          value: 'special', label: 'Special', description: 'Unique cards'),
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
      FilterOption(
          value: 'standard',
          label: 'Standard',
          description: 'Current competitive format'),
      FilterOption(
          value: 'modern',
          label: 'Modern',
          description: 'Cards from 2003 onwards'),
      FilterOption(
          value: 'legacy',
          label: 'Legacy',
          description: 'All cards except banned'),
      FilterOption(
          value: 'vintage',
          label: 'Vintage',
          description: 'All cards with restrictions'),
      FilterOption(
          value: 'commander',
          label: 'Commander',
          description: '100-card singleton'),
      FilterOption(
          value: 'pioneer',
          label: 'Pioneer',
          description: 'Cards from Return to Ravnica onwards'),
      FilterOption(
          value: 'historic', label: 'Historic', description: 'Arena format'),
      FilterOption(
          value: 'pauper', label: 'Pauper', description: 'Commons only'),
      FilterOption(
          value: 'brawl',
          label: 'Brawl',
          description: 'Standard-legal Commander'),
      FilterOption(
          value: 'future', label: 'Future', description: 'Upcoming releases'),
    ];

    _filterCache['formats'] = options;
    return options;
  }

  /// Clear the filter cache (useful for refreshing data)
  void clearFilterCache() {
    _filterCache.clear();
  }

  /// Check if the service is available (legacy method)
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

  // INTERNAL METHODS

  // Core API request method with comprehensive error handling
  Future<Result<String>> _makeApiRequest(String path) async {
    const maxAttempts = 3;
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        await _waitForRateLimit();

        final url = '${_config.apiBaseUrl}$path';
        logDebug('Making API request',
            context: {'url': url, 'attempt': attempts + 1});

        final response = await _httpClient.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'MTGCardDisplay/1.0',
          },
        ).timeout(Duration(seconds: _config.apiTimeout));

        _lastRequestTime = DateTime.now();

        if (response.statusCode == 200) {
          _recordSuccess();
          return Success(response.body);
        } else if (response.statusCode == 429) {
          // Rate limited, wait longer
          logWarning('Rate limited, waiting longer');
          await Future.delayed(const Duration(seconds: 2));
        } else {
          final error = ApiError(
            message: 'API request failed',
            statusCode: response.statusCode,
            originalError: response.body,
          );

          logWarning('API request failed', context: {
            'status_code': response.statusCode,
            'response': response.body,
          });

          _recordFailure();
          return Failure(error);
        }
      } on TimeoutException {
        logWarning('Request timed out', context: {'attempt': attempts + 1});
        _recordFailure();
        return const Failure(NetworkError(message: 'Request timed out'));
      } on SocketException catch (e) {
        logWarning('Network error',
            error: e, context: {'attempt': attempts + 1});
        if (attempts == maxAttempts - 1) {
          _recordFailure();
          return Failure(
              NetworkError(message: 'Network error', originalError: e));
        }
      } on HttpException catch (e) {
        logWarning('HTTP error', error: e, context: {'attempt': attempts + 1});
        if (attempts == maxAttempts - 1) {
          _recordFailure();
          return Failure(NetworkError(message: 'HTTP error', originalError: e));
        }
      } catch (e) {
        logError('Unexpected error during API request', error: e);
        _recordFailure();
        return Failure(
            UnknownError(message: 'Unexpected error', originalError: e));
      }

      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    _recordFailure();
    return const Failure(NetworkError(message: 'Max retry attempts exceeded'));
  }

  /// Make HTTP request with retry logic (legacy method)
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
        debugPrint('Network error, attempt ${attempts + 1}/$maxAttempts');
      } on HttpException {
        debugPrint('HTTP error, attempt ${attempts + 1}/$maxAttempts');
      } catch (e) {
        debugPrint('Request error: $e, attempt ${attempts + 1}/$maxAttempts');
      }

      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw Exception('Failed to make request after $maxAttempts attempts');
  }

  // Wait for rate limit compliance
  Future<void> _waitForRateLimit() async {
    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime);
    if (timeSinceLastRequest < _rateLimitDelay) {
      await Future.delayed(_rateLimitDelay - timeSinceLastRequest);
    }
  }

  // Build search query string
  String _buildSearchQuery({
    String? query,
    List<String>? sets,
    List<String>? colors,
    List<String>? types,
    List<String>? rarity,
    String? format,
  }) {
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

    return queryParts.join(' ');
  }
}

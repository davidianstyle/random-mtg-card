import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/mtg_card.dart';
import '../utils/result.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';
import 'cache_service.dart';
import 'config_service.dart';
import 'service_locator.dart';

// Enhanced Scryfall service with better error handling and caching
class EnhancedScryfallService extends Service with PerformanceMonitoring, LoggerExtension {
  static EnhancedScryfallService? _instance;
  static EnhancedScryfallService get instance => _instance ??= EnhancedScryfallService._();

  EnhancedScryfallService._();

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

  Future<void> initialize() async {
    _config = getService<ConfigService>();
    _cache = getService<CacheService>();
    _httpClient = http.Client();
    
    logInfo('Enhanced Scryfall service initialized');
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  // Circuit breaker check
  bool get _isCircuitBreakerOpen {
    if (_circuitBreakerOpenTime == null) return false;
    if (DateTime.now().difference(_circuitBreakerOpenTime!) > _circuitBreakerTimeout) {
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
      logWarning('Circuit breaker opened due to ${_failureCount} consecutive failures');
    }
  }

  void _recordSuccess() {
    _failureCount = 0;
    _circuitBreakerOpenTime = null;
  }

  // Enhanced random card fetch with caching and error handling
  Future<Result<MTGCard>> getRandomCard() async {
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
            
            logInfo('Random card fetched successfully', context: {'card_id': card.id});
            return Success(card);
          },
          (error) => Failure(error),
        );
      } catch (e, stackTrace) {
        logError('Failed to get random card', error: e, stackTrace: stackTrace);
        return Failure(UnknownError(message: 'Failed to get random card', originalError: e));
      }
    });
  }

  // Enhanced card search with pagination and filtering
  Future<Result<List<MTGCard>>> searchCards({
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
          return Success(data.map((cardJson) => MTGCard.fromJson(cardJson)).toList());
        }

        // Make API request
        final url = '/cards/search?q=${Uri.encodeComponent(searchQuery)}&page=$page';
        final result = await _makeApiRequest(url);
        
        return result.fold(
          (response) async {
            final json = jsonDecode(response);
            final data = json['data'] as List;
            final cards = data.map((cardJson) => MTGCard.fromJson(cardJson)).toList();
            
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
        return Failure(UnknownError(message: 'Failed to search cards', originalError: e));
      }
    });
  }

  // Get specific card by ID
  Future<Result<MTGCard>> getCard(String id) async {
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
        logError('Failed to get card', error: e, stackTrace: stackTrace, 
            context: {'card_id': id});
        return Failure(UnknownError(message: 'Failed to get card', originalError: e));
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
        return Failure(UnknownError(message: 'Failed to get card image', originalError: e));
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
        return Failure(UnknownError(message: 'Service check failed', originalError: e));
      }
    });
  }

  // Core API request method with comprehensive error handling
  Future<Result<String>> _makeApiRequest(String path) async {
    const maxAttempts = 3;
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        await _waitForRateLimit();

        final url = '${_config.apiBaseUrl}$path';
        logDebug('Making API request', context: {'url': url, 'attempt': attempts + 1});

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
        logWarning('Network error', error: e, context: {'attempt': attempts + 1});
        if (attempts == maxAttempts - 1) {
          _recordFailure();
          return Failure(NetworkError(message: 'Network error', originalError: e));
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
        return Failure(UnknownError(message: 'Unexpected error', originalError: e));
      }

      attempts++;
      if (attempts < maxAttempts) {
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    _recordFailure();
    return const Failure(NetworkError(message: 'Max retry attempts exceeded'));
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

// Extension to add Result handling to existing methods
extension ScryfallServiceExtensions on EnhancedScryfallService {
  // Convert Result to nullable for backward compatibility
  Future<MTGCard?> getRandomCardLegacy() async {
    final result = await getRandomCard();
    return result.dataOrNull;
  }

  Future<List<MTGCard>> searchCardsLegacy({
    String? query,
    List<String>? sets,
    List<String>? colors,
    List<String>? types,
    List<String>? rarity,
    String? format,
    int page = 1,
  }) async {
    final result = await searchCards(
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

  Future<MTGCard?> getCardLegacy(String id) async {
    final result = await getCard(id);
    return result.dataOrNull;
  }
} 
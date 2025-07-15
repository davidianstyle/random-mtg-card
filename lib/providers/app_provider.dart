import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mtg_card.dart';
import '../services/config_service.dart';
import '../services/service_locator.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';

class AppProvider extends ChangeNotifier
    with LoggerExtension, PerformanceMonitoring {
  static const String _favoritesKey = 'favorites';

  List<String> _favoriteCardIds = [];
  List<MTGCard> _favoriteCards = [];
  bool _showMetadata = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final ConfigService _config;

  // Getters
  List<String> get favoriteCardIds => _favoriteCardIds;
  List<MTGCard> get favoriteCards => _favoriteCards;
  bool get showMetadata => _showMetadata;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize the provider
  Future<void> initialize() async {
    return timeAsync('initializeAppProvider', () async {
      try {
        // Get services from service locator
        _config = getService<ConfigService>();

        logInfo('App provider initialized');
        await _loadFavorites();
      } catch (e, stackTrace) {
        logError('Failed to initialize app provider',
            error: e, stackTrace: stackTrace);
        _setError('Failed to initialize app provider');
      }
    });
  }

  // Favorites management
  bool isFavorite(String? cardId) {
    if (cardId == null) return false;
    return _favoriteCardIds.contains(cardId);
  }

  Future<void> toggleFavorite(MTGCard card) async {
    if (_favoriteCardIds.contains(card.id)) {
      await removeFavorite(card.id);
    } else {
      await addFavorite(card);
    }
  }

  Future<void> addFavorite(MTGCard card) async {
    if (!_favoriteCardIds.contains(card.id)) {
      _favoriteCardIds.add(card.id);
      _favoriteCards.add(card);
      await _saveFavorites();
      notifyListeners();

      logInfo('Card added to favorites', context: {
        'card_id': card.id,
        'card_name': card.name,
        'total_favorites': _favoriteCardIds.length,
      });
    }
  }

  Future<void> removeFavorite(String cardId) async {
    final removedCard = _favoriteCards.firstWhere((card) => card.id == cardId,
        orElse: () => MTGCard(
            id: cardId,
            name: 'Unknown',
            typeLine: '',
            set: '',
            setName: '',
            rarity: ''));

    _favoriteCardIds.remove(cardId);
    _favoriteCards.removeWhere((card) => card.id == cardId);
    await _saveFavorites();
    notifyListeners();

    logInfo('Card removed from favorites', context: {
      'card_id': cardId,
      'card_name': removedCard.name,
      'total_favorites': _favoriteCardIds.length,
    });
  }

  Future<void> clearFavorites() async {
    _favoriteCardIds.clear();
    _favoriteCards.clear();
    await _saveFavorites();
    notifyListeners();
  }

  // Metadata visibility
  void toggleMetadata() {
    _showMetadata = !_showMetadata;
    notifyListeners();
  }

  void setShowMetadata(bool show) {
    _showMetadata = show;
    notifyListeners();
  }

  void hideMetadata() {
    _showMetadata = false;
    notifyListeners();
  }

  // Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error handling
  void setError(String? error) {
    _errorMessage = error;
    if (error != null) {
      logError('App provider error set', context: {'error': error});
    }
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      logDebug('App provider error cleared');
    }
    _errorMessage = null;
    notifyListeners();
  }

  // Private helper for setting errors
  void _setError(String error) {
    setError(error);
  }

  // Auto-hide metadata after delay
  void autoHideMetadata() {
    if (_config.showMetadataOnTap) {
      Future.delayed(Duration(seconds: _config.metadataAutoHideDelay), () {
        hideMetadata();
      });
    }
  }

  // Private methods
  Future<void> _loadFavorites() async {
    return timeAsync('loadFavorites', () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final favoritesJson = prefs.getString(_favoritesKey);

        if (favoritesJson != null) {
          final favoritesList = jsonDecode(favoritesJson) as List<dynamic>;

          for (final favoriteJson in favoritesList) {
            final favoriteData = favoriteJson as Map<String, dynamic>;
            final cardId = favoriteData['id'] as String;

            _favoriteCardIds.add(cardId);

            // Try to restore full card data if available
            if (favoriteData['cardData'] != null) {
              try {
                final card = MTGCard.fromJson(favoriteData['cardData']);
                _favoriteCards.add(card);
              } catch (e) {
                // If card data is corrupted, just keep the ID
                logWarning('Error loading favorite card data',
                    error: e,
                    context: {
                      'card_id': cardId,
                    });
              }
            }
          }

          logInfo('Favorites loaded successfully', context: {
            'favorites_count': _favoriteCardIds.length,
          });
        } else {
          logDebug('No favorites found');
        }
      } catch (e, stackTrace) {
        logError('Error loading favorites', error: e, stackTrace: stackTrace);
      }
    });
  }

  Future<void> _saveFavorites() async {
    return timeAsync('saveFavorites', () async {
      try {
        final prefs = await SharedPreferences.getInstance();

        final favoritesList = <Map<String, dynamic>>[];

        for (int i = 0; i < _favoriteCardIds.length; i++) {
          final cardId = _favoriteCardIds[i];
          final favoriteData = <String, dynamic>{
            'id': cardId,
            'added_date': DateTime.now().toIso8601String(),
          };

          // Include full card data if available
          if (i < _favoriteCards.length) {
            favoriteData['cardData'] = _favoriteCards[i].toJson();
          }

          favoritesList.add(favoriteData);
        }

        final favoritesJson = jsonEncode(favoritesList);
        await prefs.setString(_favoritesKey, favoritesJson);

        logDebug('Favorites saved successfully', context: {
          'favorites_count': _favoriteCardIds.length,
        });
      } catch (e, stackTrace) {
        logError('Error saving favorites', error: e, stackTrace: stackTrace);
      }
    });
  }

  // Export favorites (for backup/sharing)
  String exportFavorites() {
    final exportData = {
      'favorites': _favoriteCards.map((card) => card.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    return jsonEncode(exportData);
  }

  // Import favorites (from backup/sharing)
  Future<bool> importFavorites(String jsonData) async {
    try {
      final importData = jsonDecode(jsonData) as Map<String, dynamic>;
      final favoritesData = importData['favorites'] as List<dynamic>;

      final importedCards = <MTGCard>[];
      final importedIds = <String>[];

      for (final cardData in favoritesData) {
        final card = MTGCard.fromJson(cardData);
        importedCards.add(card);
        importedIds.add(card.id);
      }

      _favoriteCards = importedCards;
      _favoriteCardIds = importedIds;
      await _saveFavorites();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error importing favorites: $e');
      return false;
    }
  }

  // Clear all favorites
  void clearAllFavorites() {
    _favoriteCards.clear();
    _favoriteCardIds.clear();
    _saveFavorites();
    notifyListeners();
  }

  // Toggle metadata overlay (for tests)
  void showMetadataOverlay() {
    _showMetadata = true;
    notifyListeners();
  }
}

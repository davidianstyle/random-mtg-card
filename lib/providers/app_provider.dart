import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mtg_card.dart';
import '../services/config_service.dart';

class AppProvider extends ChangeNotifier {
  static const String _favoritesKey = 'favorites';

  List<String> _favoriteCardIds = [];
  List<MTGCard> _favoriteCards = [];
  bool _showMetadata = false;
  bool _isLoading = false;
  String? _errorMessage;

  final ConfigService _config = ConfigService.instance;

  // Getters
  List<String> get favoriteCardIds => _favoriteCardIds;
  List<MTGCard> get favoriteCards => _favoriteCards;
  bool get showMetadata => _showMetadata;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize the provider
  Future<void> initialize() async {
    await _loadFavorites();
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
    }
  }

  Future<void> removeFavorite(String cardId) async {
    _favoriteCardIds.remove(cardId);
    _favoriteCards.removeWhere((card) => card.id == cardId);
    await _saveFavorites();
    notifyListeners();
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
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
              debugPrint('Error loading favorite card data: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
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
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
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

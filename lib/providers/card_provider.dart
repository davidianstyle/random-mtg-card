import 'package:flutter/material.dart';

import '../models/mtg_card.dart';
import '../services/scryfall_service.dart';
import '../services/config_service.dart';

class CardProvider extends ChangeNotifier {
  final ScryfallService _scryfallService = ScryfallService.instance;
  final ConfigService _config = ConfigService.instance;
  
  MTGCard? _currentCard;
  List<MTGCard> _cardHistory = [];
  int _currentIndex = -1;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  MTGCard? get currentCard => _currentCard;
  List<MTGCard> get cardHistory => _cardHistory;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get canGoBack => _currentIndex > 0;
  bool get canGoForward => _currentIndex < _cardHistory.length - 1;
  
  // Initialize and load first card
  Future<void> initialize() async {
    await loadRandomCard();
  }
  
  // Load a new random card
  Future<void> loadRandomCard() async {
    _setLoading(true);
    _clearError();
    
    try {
      final card = await _scryfallService.getRandomCardWithFilters();
      if (card != null) {
        _setCurrentCard(card);
      } else {
        _setError('Failed to load card');
      }
    } catch (e) {
      _setError('Error loading card: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Navigate to previous card
  Future<void> goToPreviousCard() async {
    if (canGoBack) {
      _currentIndex--;
      _currentCard = _cardHistory[_currentIndex];
      notifyListeners();
    } else {
      // If at the beginning, load a new card
      await loadRandomCard();
    }
  }
  
  // Navigate to next card
  Future<void> goToNextCard() async {
    if (canGoForward) {
      _currentIndex++;
      _currentCard = _cardHistory[_currentIndex];
      notifyListeners();
    } else {
      // If at the end, load a new card
      await loadRandomCard();
    }
  }
  
  // Load a specific card by ID
  Future<void> loadCard(String cardId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final card = await _scryfallService.getCard(cardId);
      if (card != null) {
        _setCurrentCard(card);
      } else {
        _setError('Card not found');
      }
    } catch (e) {
      _setError('Error loading card: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Refresh current card (reload from API)
  Future<void> refreshCurrentCard() async {
    if (_currentCard != null) {
      await loadCard(_currentCard!.id);
    } else {
      await loadRandomCard();
    }
  }
  
  // Handle swipe gestures
  Future<void> handleSwipe(bool isLeftSwipe) async {
    if (isLeftSwipe) {
      await goToNextCard();
    } else {
      await goToPreviousCard();
    }
  }
  
  // Auto-refresh functionality
  void startAutoRefresh() {
    if (_config.autoRefreshInterval > 0) {
      Future.delayed(Duration(seconds: _config.autoRefreshInterval), () {
        if (_config.autoRefreshInterval > 0) {
          loadRandomCard().then((_) => startAutoRefresh());
        }
      });
    }
  }
  
  void stopAutoRefresh() {
    // Auto-refresh is stopped by setting interval to 0 in config
  }
  
  // Clear history
  void clearHistory() {
    _cardHistory.clear();
    _currentIndex = -1;
    notifyListeners();
  }
  
  // Get card at specific index
  MTGCard? getCardAtIndex(int index) {
    if (index >= 0 && index < _cardHistory.length) {
      return _cardHistory[index];
    }
    return null;
  }
  
  // Jump to specific card in history
  void jumpToCard(int index) {
    if (index >= 0 && index < _cardHistory.length) {
      _currentIndex = index;
      _currentCard = _cardHistory[index];
      notifyListeners();
    }
  }
  
  // Private methods
  void _setCurrentCard(MTGCard card) {
    _currentCard = card;
    
    // Add to history
    if (_currentIndex < _cardHistory.length - 1) {
      // Remove cards after current position (user navigated back and got new card)
      _cardHistory.removeRange(_currentIndex + 1, _cardHistory.length);
    }
    
    _cardHistory.add(card);
    _currentIndex = _cardHistory.length - 1;
    
    // Limit history size to prevent memory issues
    const maxHistorySize = 50;
    if (_cardHistory.length > maxHistorySize) {
      _cardHistory.removeAt(0);
      _currentIndex--;
    }
    
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Get history info for debugging
  String getHistoryInfo() {
    return 'History: ${_cardHistory.length} cards, current index: $_currentIndex';
  }
  
  // Preload next card for better performance
  Future<void> preloadNextCard() async {
    try {
      final nextCard = await _scryfallService.getRandomCardWithFilters();
      if (nextCard != null) {
        // Cache the next card image
        // This could be implemented with a caching service
        print('Preloaded next card: ${nextCard.name}');
      }
    } catch (e) {
      print('Error preloading next card: $e');
    }
  }
} 
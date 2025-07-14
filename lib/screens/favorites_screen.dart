import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_provider.dart';
import '../models/mtg_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // name, added_date, set, rarity
  bool _sortAscending = true;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MTGCard> _getFilteredAndSortedCards(List<MTGCard> cards) {
    // Filter by search query
    var filteredCards = cards;
    if (_searchQuery.isNotEmpty) {
      filteredCards = cards.where((card) {
        return card.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               card.setName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               card.typeLine.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               card.rarity.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort cards
    filteredCards.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'set':
          comparison = a.setName.compareTo(b.setName);
          break;
        case 'rarity':
          // Custom rarity order
          final rarityOrder = ['common', 'uncommon', 'rare', 'mythic', 'special', 'bonus'];
          final aIndex = rarityOrder.indexOf(a.rarity.toLowerCase());
          final bIndex = rarityOrder.indexOf(b.rarity.toLowerCase());
          comparison = aIndex.compareTo(bIndex);
          break;
        case 'added_date':
          // This would require storing the date when the card was added to favorites
          // For now, we'll use the card's name as a fallback
          comparison = a.name.compareTo(b.name);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    return filteredCards;
  }

  void _showCardDetails(MTGCard card) {
    showDialog(
      context: context,
      builder: (context) => CardDetailsDialog(card: card),
    );
  }

  void _clearAllFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Clear All Favorites',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to remove all cards from your favorites? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).clearAllFavorites();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All favorites cleared!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, color: _sortBy == 'name' ? Colors.blue : Colors.white70),
                    const SizedBox(width: 8),
                    Text('Sort by Name', style: TextStyle(color: _sortBy == 'name' ? Colors.blue : Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'set',
                child: Row(
                  children: [
                    Icon(Icons.library_books, color: _sortBy == 'set' ? Colors.blue : Colors.white70),
                    const SizedBox(width: 8),
                    Text('Sort by Set', style: TextStyle(color: _sortBy == 'set' ? Colors.blue : Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rarity',
                child: Row(
                  children: [
                    Icon(Icons.star, color: _sortBy == 'rarity' ? Colors.blue : Colors.white70),
                    const SizedBox(width: 8),
                    Text('Sort by Rarity', style: TextStyle(color: _sortBy == 'rarity' ? Colors.blue : Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearAllFavorites,
            tooltip: 'Clear all favorites',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final favoriteCards = appProvider.favoriteCards;
          final filteredCards = _getFilteredAndSortedCards(favoriteCards);

          return Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search favorites...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              
              // Stats bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredCards.length} of ${favoriteCards.length} cards',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Sort: $_sortBy ${_sortAscending ? '↑' : '↓'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              // Cards grid
              Expanded(
                child: favoriteCards.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No favorites yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Double-tap cards to add them to your favorites',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : filteredCards.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No cards match your search',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredCards.length,
                            itemBuilder: (context, index) {
                              final card = filteredCards[index];
                              return FavoriteCardTile(
                                card: card,
                                onTap: () => _showCardDetails(card),
                                onRemove: () {
                                  appProvider.toggleFavorite(card);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${card.name} removed from favorites'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FavoriteCardTile extends StatelessWidget {
  final MTGCard card;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const FavoriteCardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.grey[800],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: CachedNetworkImage(
                    imageUrl: card.imageUris?.normal ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
            
            // Card info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${card.setName} • ${card.rarity}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          card.typeLine,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red, size: 16),
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Remove from favorites',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardDetailsDialog extends StatelessWidget {
  final MTGCard card;

  const CardDetailsDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      card.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            // Card image
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: CachedNetworkImage(
                  imageUrl: card.imageUris?.normal ?? '',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ),
            
            // Card details
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${card.setName} • ${card.rarity}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.typeLine,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (card.oracleText?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      card.oracleText!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
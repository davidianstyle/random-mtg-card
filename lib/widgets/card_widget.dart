import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/mtg_card.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';

class CardWidget extends StatelessWidget
    with LoggerExtension, PerformanceMonitoring {
  final MTGCard? card;

  const CardWidget({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return _buildNoCardPlaceholder();
    }

    return Center(
      child: Semantics(
        label: 'Magic: The Gathering card: ${card!.name}',
        hint:
            'Card of type ${card!.typeLine}${card!.manaCost != null ? ' with mana cost ${card!.manaCost}' : ''}',
        child: Container(
          width: 540,
          height: 756,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCardImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage() {
    final imageUrl = card!.bestImageUrl;

    if (imageUrl == null) {
      logWarning('No image URL available for card', context: {
        'card_id': card!.id,
        'card_name': card!.name,
      });
      return _buildPlaceholder();
    }

    logDebug('Loading card image', context: {
      'card_id': card!.id,
      'image_url': imageUrl,
    });

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) {
        logError('Failed to load card image', error: error, context: {
          'card_id': card!.id,
          'image_url': url,
        });
        return _buildErrorPlaceholder();
      },
      memCacheWidth: 540,
      memCacheHeight: 756,
      maxWidthDiskCache: 540,
      maxHeightDiskCache: 756,
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: 540,
      height: 756,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
            ),
            SizedBox(height: 16),
            Text(
              'Loading card...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCardPlaceholder() {
    return Semantics(
      label: 'No card available',
      hint: 'No Magic: The Gathering card is currently loaded',
      child: Container(
        width: 540,
        height: 756,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade800.withValues(alpha: 0.9),
              Colors.grey.shade900.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade600,
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                size: 48,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                'No card to display',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: 540,
      height: 756,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red[900]!,
            Colors.red[800]!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load card image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              card!.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              card!.setInfo,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 540,
      height: 756,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.grey[700]!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No image available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              card!.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              card!.typeLine,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              card!.setInfo,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

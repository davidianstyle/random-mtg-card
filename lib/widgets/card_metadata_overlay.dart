import 'package:flutter/material.dart';

import '../models/mtg_card.dart';

class CardMetadataOverlay extends StatelessWidget {
  final MTGCard card;

  const CardMetadataOverlay({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card name and mana cost
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (card.manaCost != null && card.manaCost!.isNotEmpty)
                Text(
                  card.manaCost!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Type line
          Text(
            card.typeLine,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          // Set info and rarity
          Row(
            children: [
              Expanded(
                child: Text(
                  card.setInfo,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRarityColor(card.rarity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  card.rarity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Power/Toughness for creatures
          if (card.powerToughness != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Power/Toughness: ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                Text(
                  card.powerToughness!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          // Artist
          if (card.artist != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Artist: ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                Text(
                  card.artist!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey[600]!;
      case 'uncommon':
        return Colors.grey[400]!;
      case 'rare':
        return Colors.yellow[700]!;
      case 'mythic':
        return Colors.red[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

import 'package:flutter/material.dart';

class FavoriteIndicator extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  
  const FavoriteIndicator({
    super.key,
    required this.isFavorite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white70,
          size: 20,
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../../data/models/shorts_model.dart';

class ShortCard extends StatelessWidget {
  final Short short;
  final VoidCallback onTap;

  const ShortCard({
    super.key,
    required this.short,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 280,
                width: 160,
                color: Colors.grey[900],
                child: Image.network(
                  short.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.play_circle_outline,
                          size: 60, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              short.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              short.views,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


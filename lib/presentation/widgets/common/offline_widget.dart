import 'package:flutter/material.dart';

class OfflineWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;
  
  const OfflineWidget({
    super.key,
    this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Offline Icon with glassy effect
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[800]!.withValues(alpha: 0.3),
                    Colors.grey[900]!.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message ?? 'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Retry Button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Hint text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Downloaded videos are available in Library',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
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


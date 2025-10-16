import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Colors.red;
  static const Color backgroundColor = Colors.white;
  static const Color textPrimaryColor = Colors.black;
  static final Color textSecondaryColor = Colors.grey[600]!;
  static final Color dividerColor = Colors.grey[300]!;
  
  // Default Images
  static const String defaultUserAvatar = 'https://i.pravatar.cc/150?img=1';
  static const String defaultChannelAvatar = 'https://i.pravatar.cc/150?img=2';
  
  // Firestore Collections
  static const String videosCollection = 'videos';
  static const String commentsCollection = 'comments';
  
  // Animations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  // Sizes
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  
  // Text Styles
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  
  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );
  
  static TextStyle captionTextStyle = TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
  );
}


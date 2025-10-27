class VideoQuality {
  static const String auto = 'Auto';
  static const String q360p = '360p';
  static const String q480p = '480p';
  static const String q720p = '720p';
  static const String q1080p = '1080p';
  
  static List<String> get allQualities => [auto, q360p, q480p, q720p, q1080p];
}

class VideoQualityHelper {
  /// Transform Cloudinary video URL to specific quality
  static String getQualityUrl(String originalUrl, String quality) {
    if (!originalUrl.contains('cloudinary.com')) {
      // Not a Cloudinary URL, return as is
      return originalUrl;
    }

    // Remove any existing quality transformations
    String cleanUrl = originalUrl;
    final transformations = [
      '/q_auto:low/', '/q_auto:good/', '/q_auto:best/',
      '/q_30/', '/q_50/', '/q_70/', '/q_90/',
      '/w_640/', '/w_854/', '/w_1280/', '/w_1920/',
      '/h_360/', '/h_480/', '/h_720/', '/h_1080/',
      '/c_scale/', '/c_fit/', '/c_fill/',
    ];
    
    for (var transform in transformations) {
      cleanUrl = cleanUrl.replaceAll(transform, '/');
    }

    // Apply quality transformation based on selection
    String transformation;
    switch (quality) {
      case VideoQuality.q360p:
        transformation = 'q_auto:low,w_640,c_scale';
        break;
      case VideoQuality.q480p:
        transformation = 'q_auto:good,w_854,c_scale';
        break;
      case VideoQuality.q720p:
        transformation = 'q_auto:good,w_1280,c_scale';
        break;
      case VideoQuality.q1080p:
        transformation = 'q_auto:best,w_1920,c_scale';
        break;
      case VideoQuality.auto:
      default:
        return originalUrl; // Return original for auto/best quality
    }

    // Insert transformation into Cloudinary URL
    // Format: https://res.cloudinary.com/cloud/video/upload/TRANSFORM/video.mp4
    if (cleanUrl.contains('/video/upload/')) {
      return cleanUrl.replaceFirst(
        '/video/upload/',
        '/video/upload/$transformation/',
      );
    }

    return originalUrl;
  }

  /// Get quality label for display
  static String getQualityLabel(String quality) {
    switch (quality) {
      case VideoQuality.q360p:
        return '360p (Low)';
      case VideoQuality.q480p:
        return '480p (Medium)';
      case VideoQuality.q720p:
        return '720p (HD)';
      case VideoQuality.q1080p:
        return '1080p (Full HD)';
      case VideoQuality.auto:
      default:
        return 'Auto (Best)';
    }
  }
}


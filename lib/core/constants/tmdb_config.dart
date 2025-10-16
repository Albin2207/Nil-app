class TmdbConfig {
  // Get your API key from: https://www.themoviedb.org/settings/api
  static const String apiKey = '21d548f63198d5d5c735a3130e13e454';
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';
  
  // Image sizes
  static const String posterSizeSmall = '/w342';
  static const String posterSizeMedium = '/w500';
  static const String posterSizeLarge = '/w780';
  static const String backdropSize = '/w1280';
  static const String profileSize = '/w185';
  
  // API Endpoints
  static String get trendingMovies => '$baseUrl/trending/movie/week?api_key=$apiKey';
  static String get popularMovies => '$baseUrl/movie/popular?api_key=$apiKey';
  static String get topRatedMovies => '$baseUrl/movie/top_rated?api_key=$apiKey';
  static String get nowPlayingMovies => '$baseUrl/movie/now_playing?api_key=$apiKey';
  static String get upcomingMovies => '$baseUrl/movie/upcoming?api_key=$apiKey';
  
  static String get popularTvShows => '$baseUrl/tv/popular?api_key=$apiKey';
  static String get topRatedTvShows => '$baseUrl/tv/top_rated?api_key=$apiKey';
  
  static String movieDetails(int id) => '$baseUrl/movie/$id?api_key=$apiKey&append_to_response=videos,credits,similar';
  static String tvDetails(int id) => '$baseUrl/tv/$id?api_key=$apiKey&append_to_response=videos,credits,similar';
  static String searchMovies(String query) => '$baseUrl/search/movie?api_key=$apiKey&query=$query';
  
  // Helper methods
  static String getPosterUrl(String? path, {String size = '/w500'}) {
    if (path == null || path.isEmpty) return '';
    return '$imageBaseUrl$size$path';
  }
  
  static String getBackdropUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '$imageBaseUrl$backdropSize$path';
  }
}


import 'package:dio/dio.dart';
import '../models/movie_tmdb_model.dart';
import '../../core/constants/tmdb_config.dart';

class TmdbRepository {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    validateStatus: (status) => status! < 500,
  ));

  Future<List<MovieTmdb>> getTrendingMovies() async {
    return _fetchMovies(TmdbConfig.trendingMovies);
  }

  Future<List<MovieTmdb>> getPopularMovies() async {
    return _fetchMovies(TmdbConfig.popularMovies);
  }

  Future<List<MovieTmdb>> getTopRatedMovies() async {
    return _fetchMovies(TmdbConfig.topRatedMovies);
  }

  Future<List<MovieTmdb>> getNowPlayingMovies() async {
    return _fetchMovies(TmdbConfig.nowPlayingMovies);
  }

  Future<List<MovieTmdb>> getUpcomingMovies() async {
    return _fetchMovies(TmdbConfig.upcomingMovies);
  }

  Future<List<MovieTmdb>> getPopularTvShows() async {
    return _fetchMovies(TmdbConfig.popularTvShows);
  }

  Future<MovieDetails> getMovieDetails(int id) async {
    try {
      final response = await _dio.get(TmdbConfig.movieDetails(id));
      
      if (response.statusCode == 200) {
        return MovieDetails.fromJson(response.data);
      } else {
        throw Exception('Failed to load movie details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching movie details: $e');
      throw Exception('Error fetching movie details: $e');
    }
  }

  Future<List<MovieTmdb>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    return _fetchMovies(TmdbConfig.searchMovies(query));
  }

  Future<List<MovieTmdb>> _fetchMovies(String url) async {
    try {
      print('🎬 Fetching movies from: $url');
      final response = await _dio.get(url);
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        print('✅ Got ${results.length} movies');
        return results.map((json) => MovieTmdb.fromJson(json)).toList();
      } else {
        print('❌ API returned: ${response.statusCode}');
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching movies: $e');
      throw Exception('Network error. Please check internet connection.');
    }
  }
}

